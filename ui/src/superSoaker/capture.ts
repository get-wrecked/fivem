//=-- SuperSoaker NUI capture: turns game frame into water and handles fill/shoot flows.

import {
    CfxTexture,
    LinearFilter,
    Mesh,
    NearestFilter,
    OrthographicCamera,
    PlaneBufferGeometry,
    RGBAFormat,
    Scene,
    ShaderMaterial,
    UnsignedByteType,
    WebGLRenderer,
    WebGLRenderTarget,
} from '@citizenfx/three';
import { hasMedal, screenshot } from '@/lib/medal';

/** Output encoding type for screenshots. */
type Encoding = 'jpg' | 'png' | 'webp';

/**
 * Describes a capture/upload request sent from Lua to the NUI.
 *
 * The UI either returns the image back to the game (fill) via `resultURL`
 * or uploads it to `targetURL` (shoot) and then posts the upload result
 * to `resultURL` if provided.
 */
interface SoakerRequest {
    /** Output encoding. */
    encoding: Encoding;
    /** 0..1 image quality for jpg/webp. */
    quality?: number;
    /** Additional headers when uploading. */
    headers?: Record<string, string>;
    /** Correlation id from Lua to match async responses. */
    correlation: string;
    /** Callback endpoint back into the game (NUI -> Lua). */
    resultURL?: string | null;
    /** Optional upload endpoint for shoot mode. */
    targetURL?: string | null;
    /** Form field name used when uploading a Blob. */
    targetField?: string | null;
}

/** Converts a data URI string to a Blob for form uploads. */
function dataURItoBlob(dataURI: string) {
    const byteString = atob(dataURI.split(',')[1]);
    const mimeString = dataURI.split(',')[0].split(':')[1].split(';')[0];
    const ab = new ArrayBuffer(byteString.length);
    const ia = new Uint8Array(ab);
    for (let i = 0; i < byteString.length; i++) ia[i] = byteString.charCodeAt(i);
    return new Blob([ab], { type: mimeString });
}

/** Manages Three/WebGL capture and NUI messaging for SuperSoaker. */
class SoakerUI {
    // biome-ignore lint/suspicious/noExplicitAny: @citizenfx/three lacks types
    private renderer: any | null = null;
    // biome-ignore lint/suspicious/noExplicitAny: @citizenfx/three lacks types
    private rtTexture: any | null = null;
    // biome-ignore lint/suspicious/noExplicitAny: @citizenfx/three lacks types
    private sceneRTT: any | null = null;
    // biome-ignore lint/suspicious/noExplicitAny: @citizenfx/three lacks types
    private cameraRTT: any | null = null;
    // biome-ignore lint/suspicious/noExplicitAny: @citizenfx/three lacks types
    private material: any | null = null;
    private pending: SoakerRequest | null = null;
    private available = false;
    private hasMedal = false;

    /** Initializes rendering resources and message listeners. */
    async initialize() {
        //=-- Try to acquire the special Three binding from Cfx
        try {
            const cameraRTT = new OrthographicCamera(
                window.innerWidth / -2,
                window.innerWidth / 2,
                window.innerHeight / 2,
                window.innerHeight / -2,
                -10000,
                10000,
            );
            cameraRTT.position.z = 100;

            const sceneRTT = new Scene();

            const rtTexture = new WebGLRenderTarget(window.innerWidth, window.innerHeight, {
                minFilter: LinearFilter,
                magFilter: NearestFilter,
                format: RGBAFormat,
                type: UnsignedByteType,
            });

            const gameTexture = new CfxTexture();
            gameTexture.needsUpdate = true;

            const material = new ShaderMaterial({
                uniforms: { tDiffuse: { value: gameTexture } },
                vertexShader: `
          varying vec2 vUv;
          void main() {
            vUv = vec2(uv.x, 1.0-uv.y);
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
          }
        `,
                fragmentShader: `
          varying vec2 vUv;
          uniform sampler2D tDiffuse;
          void main() {
            gl_FragColor = texture2D(tDiffuse, vUv);
          }
        `,
            });

            this.material = material;

            const plane = new PlaneBufferGeometry(window.innerWidth, window.innerHeight);
            const quad = new Mesh(plane, material);
            quad.position.z = -100;
            sceneRTT.add(quad);

            const renderer = new WebGLRenderer();
            renderer.setPixelRatio(window.devicePixelRatio);
            renderer.setSize(window.innerWidth, window.innerHeight);
            renderer.autoClear = false;

            //=-- Hidden canvas container
            let holder = document.getElementById('superSoaker-root');
            if (!holder) {
                holder = document.createElement('div');
                holder.id = 'superSoaker-root';
                holder.style.display = 'none';
                document.body.appendChild(holder);
            }
            holder.appendChild(renderer.domElement);

            this.renderer = renderer;
            this.rtTexture = rtTexture;
            this.sceneRTT = sceneRTT;
            this.cameraRTT = cameraRTT;

            window.addEventListener('resize', () => this.resize());

            this.available = true;
            this.animate();
        } catch (_e) {
            //=-- Fallback: not available; we'll return a 1x1 transparent image
            this.available = false;
        }

        this.hasMedal = await hasMedal();

        //=-- Listen for capture requests from Lua
        window.addEventListener('message', (event) => {
            const req: SoakerRequest | undefined = event.data?.request || undefined;
            if (!req) return;
            this.pending = req;
        });
    }

    /**
     * Rebuilds render targets and scene geometry on window resize.
     */
    private resize() {
        if (!this.available || !this.renderer || !this.material) return;

        const cameraRTT = new OrthographicCamera(
            window.innerWidth / -2,
            window.innerWidth / 2,
            window.innerHeight / 2,
            window.innerHeight / -2,
            -10000,
            10000,
        );
        cameraRTT.position.z = 100;
        this.cameraRTT = cameraRTT;

        const sceneRTT = new Scene();
        const plane = new PlaneBufferGeometry(window.innerWidth, window.innerHeight);
        const quad = new Mesh(plane, this.material);
        quad.position.z = -100;
        sceneRTT.add(quad);
        this.sceneRTT = sceneRTT;

        this.rtTexture = new WebGLRenderTarget(window.innerWidth, window.innerHeight, {
            minFilter: LinearFilter,
            magFilter: NearestFilter,
            format: RGBAFormat,
            type: UnsignedByteType,
        });

        this.renderer.setSize(window.innerWidth, window.innerHeight);
    }

    /**
     * Starts the render loop and handles pending capture requests.
     */
    private animate() {
        if (!this.renderer || !this.sceneRTT || !this.cameraRTT || !this.rtTexture) return;

        const loop = () => {
            requestAnimationFrame(loop);
            this.renderer?.clear();
            // @ts-ignore draw to RT
            this.renderer?.render(this.sceneRTT, this.cameraRTT, this.rtTexture, true);

            if (this.pending) {
                const req = this.pending;
                this.pending = null;
                this.handleRequest(req);
            }
        };
        requestAnimationFrame(loop);
    }

    /**
     * Handles a single capture/upload request from Lua.
     * - If `targetURL` is provided, uploads the image (shoot) and posts the
     *   upload response to `resultURL` if present.
     * - Otherwise, posts the image data URI back to `resultURL` (fill).
     * @param three CitizenFX three binding.
     * @param request The capture or upload request.
     */
    private async handleRequest(request: SoakerRequest) {
        let imageURL = '';
        let type = 'image/png';

        switch (request.encoding) {
            case 'jpg':
                type = 'image/jpeg';
                break;
            case 'webp':
                type = 'image/webp';
                break;
        }

        if (this.hasMedal) {
            imageURL = await screenshot(type);
            imageURL = `data:image/png;base64,${imageURL}`;
        } else if (this.available && this.renderer && this.rtTexture) {
            const read = new Uint8Array(window.innerWidth * window.innerHeight * 4);
            // @ts-ignore
            this.renderer.readRenderTargetPixels(
                this.rtTexture,
                0,
                0,
                window.innerWidth,
                window.innerHeight,
                read,
            );

            const canvas = document.createElement('canvas');
            canvas.width = window.innerWidth;
            canvas.height = window.innerHeight;
            const d = new Uint8ClampedArray(read.buffer);
            const cxt = canvas.getContext('2d');
            cxt.putImageData(new ImageData(d, window.innerWidth, window.innerHeight), 0, 0);

            const q = request.quality ?? 0.92;
            imageURL = canvas.toDataURL(type, q);
        } else {
            //=-- 1x1 transparent fallback
            imageURL =
                'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAgMBgYt3Wq8AAAAASUVORK5CYII=';
        }

        const headers = request.headers || {};

        try {
            if (request.targetURL) {
                //=-- Shoot water: upload first, then notify resultURL
                const getForm = () => {
                    const fd = new FormData();
                    fd.append(
                        request.targetField || 'file',
                        dataURItoBlob(imageURL),
                        `soaker.${request.encoding}`,
                    );
                    return fd;
                };

                const resp = await fetch(request.targetURL, {
                    method: 'POST',
                    mode: 'cors',
                    headers,
                    body: request.targetField
                        ? getForm()
                        : JSON.stringify({ data: imageURL, id: request.correlation }),
                });
                const text = await resp.text();

                if (request.resultURL) {
                    await fetch(request.resultURL, {
                        method: 'POST',
                        mode: 'cors',
                        body: JSON.stringify({ data: text, id: request.correlation }),
                    });
                }
            } else if (request.resultURL) {
                //=-- Fill water only: send the image directly back to game
                await fetch(request.resultURL, {
                    method: 'POST',
                    mode: 'cors',
                    body: JSON.stringify({ data: imageURL, id: request.correlation }),
                });
            }
        } catch (_e) {
            // swallow
        }
    }
}

const soaker = new SoakerUI();
soaker.initialize();
