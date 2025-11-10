/*
  Medal.tv - FiveM Resource
  =========================
  File: superSoaker/src/server/server.ts
  =====================
  Description:
    HTTP handler for SuperSoaker screenshot uploads using token-based authentication.
  ---
  Exports:
    - registerUpload: Register player upload callbacks by token
    - generateToken: Generate unique tokens for upload sessions
  ---
  Globals:
    None
*/

import { setHttpCallback } from '@citizenfx/http-wrapper';
import { v4 } from 'uuid';
import * as fs from 'fs';
import Koa from 'koa';
import Router from 'koa-router';
import koaBody from 'koa-body';
import { File } from 'formidable';

//=-- Suppress only the Buffer() deprecation warning (DEP0005) from old formidable version
const originalEmitWarning = process.emitWarning;
process.emitWarning = function(warning: any, ...args: any[]) {
    if (typeof warning === 'string' && warning.includes('Buffer()')) {
        return;
    }
    if (warning && warning.name === 'DeprecationWarning' && warning.code === 'DEP0005') {
        return;
    }
    return originalEmitWarning.call(process, warning, ...args);
};

//=-- Logger interface from Lua shared-logger.lua
interface Logger {
    error(...args: any[]): void;
    warning(...args: any[]): void;
    info(...args: any[]): void;
    debug(...args: any[]): void;
}

//=-- Access global Logger from Lua
const Logger = (global as any).Logger as Logger | undefined;

const app = new Koa();
const router = new Router();

//=-- Log all incoming HTTP requests for debugging
app.use(async (ctx, next) => {
    if (Logger?.debug) {
        Logger.debug('[SuperSoaker.HTTP]', 'RAW REQUEST', `Method: ${ctx.method}`, `Path: ${ctx.path}`, `URL: ${ctx.url}`);
    } else {
        console.log(`[SuperSoaker.HTTP] RAW REQUEST - Method: ${ctx.method}, Path: ${ctx.path}, URL: ${ctx.url}`);
    }
    await next();
});

//=-- Utility to redact base64 strings for logging
function redactBase64(value: any): any {
    if (typeof value === 'string' && value.length > 100 && /^[A-Za-z0-9+/=]+$/.test(value.substring(0, 100))) {
        return `${value.substring(0, 16)}...<${value.length} chars>`;
    }
    if (typeof value === 'object' && value !== null) {
        const redacted: any = {};
        for (const key in value) {
            redacted[key] = redactBase64(value[key]);
        }
        return redacted;
    }
    return value;
}

//=-- Data structure for pending upload requests
class UploadData {
    cb: (err: string | boolean, data: string) => void;
    playerSrc: number;
}

//=-- Store pending uploads by token
const uploads: { [token: string]: UploadData } = {};

//=-- HTTP endpoint for receiving screenshot uploads
router.post('/superSoaker/upload/:token', async (ctx) => {
    const tkn: string = ctx.params['token'];
    const requestInfo = {
        method: ctx.method,
        path: ctx.path,
        token: tkn,
        ip: ctx.ip,
        contentType: ctx.request.type,
    };

    try {
        //=-- Log incoming request with redacted body
        if (Logger?.debug) {
            Logger.debug('[SuperSoaker.HTTP]', 'Incoming request:', JSON.stringify(requestInfo));
        }

        ctx.response.append('Access-Control-Allow-Origin', '*');
        ctx.response.append('Access-Control-Allow-Methods', 'POST');

        //=-- Validate token exists and is registered
        if (!tkn || typeof tkn !== 'string') {
            const error = 'Token parameter missing or invalid';
            if (Logger?.error) {
                Logger.error('[SuperSoaker.HTTP]', error, `Token: ${tkn}`);
            }
            ctx.status = 400;
            ctx.body = { success: false, error };
            return;
        }

        if (uploads[tkn] === undefined) {
            const error = 'Invalid or expired token';
            if (Logger?.error) {
                Logger.error('[SuperSoaker.HTTP]', error, `Token: ${tkn}`);
            }
            ctx.status = 404;
            ctx.body = { success: false, error };
            return;
        }

        const upload = uploads[tkn];
        delete uploads[tkn];

        const finish = (err: string | null, data: string | null) => {
            setImmediate(() => {
                if (err) {
                    if (Logger?.error) {
                        Logger.error('[SuperSoaker.HTTP]', 'Upload failed:', err, `PlayerSrc: ${upload.playerSrc}`);
                    }
                    upload.cb(err, data || '');
                } else {
                    if (Logger?.debug) {
                        Logger.debug('[SuperSoaker.HTTP]', 'Upload successful', `PlayerSrc: ${upload.playerSrc}`, `DataSize: ${data?.length || 0}`);
                    }
                    upload.cb(false, data || '');
                }
            });
        };

        //=-- Get uploaded file from multipart form (like screenshot-basic)
        const f = ctx.request.files?.['file'] as File | undefined;

        if (f) {
            //=-- Read file and convert to base64 data URI
            fs.readFile(f.path, (err, data) => {
                if (err) {
                    const error = `Failed to read uploaded file: ${err.message}`;
                    if (Logger?.error) {
                        Logger.error('[SuperSoaker.HTTP]', error, `Token: ${tkn}`);
                    }
                    finish(error, null);
                    return;
                }

                //=-- Clean up temp file
                fs.unlink(f.path, (unlinkErr) => {
                    if (unlinkErr && Logger?.debug) {
                        Logger.debug('[SuperSoaker.HTTP]', 'Failed to delete temp file:', unlinkErr.message);
                    }
                    
                    //=-- Return data in base64 data URI format
                    const dataUri = `data:${f.type || 'image/jpeg'};base64,${data.toString('base64')}`;
                    finish(null, dataUri);
                });
            });
        } else {
            const error = 'No file uploaded';
            if (Logger?.error) {
                Logger.error('[SuperSoaker.HTTP]', error, `Token: ${tkn}`);
            }
            finish(error, null);
        }

        ctx.status = 200;
        ctx.body = { success: true };
    } catch (err) {
        //=-- Catch any unexpected errors
        const errorMsg = err instanceof Error ? err.message : String(err);
        const errorStack = err instanceof Error ? err.stack : undefined;
        
        if (Logger?.error) {
            Logger.error('[SuperSoaker.HTTP]', 'Unexpected error processing upload:', errorMsg);
            if (errorStack && Logger?.debug) {
                Logger.debug('[SuperSoaker.HTTP]', 'Error stack:', errorStack);
            }
        }
        
        ctx.status = 500;
        ctx.body = { success: false, error: 'Internal server error' };
    }
});

//=-- OPTIONS handler for CORS preflight
router.options('/superSoaker/upload/:token', async (ctx) => {
    try {
        if (Logger?.debug) {
            Logger.debug('[SuperSoaker.HTTP]', 'CORS preflight:', ctx.path);
        }
        
        ctx.response.append('Access-Control-Allow-Origin', '*');
        ctx.response.append('Access-Control-Allow-Methods', 'POST, OPTIONS');
        ctx.response.append('Access-Control-Allow-Headers', 'Content-Type');
        ctx.status = 204;
    } catch (err) {
        const errorMsg = err instanceof Error ? err.message : String(err);
        if (Logger?.error) {
            Logger.error('[SuperSoaker.HTTP]', 'Error handling OPTIONS request:', errorMsg);
        }
        ctx.status = 500;
    }
});

//=-- Global error handler middleware
app.use(async (ctx, next) => {
    try {
        await next();
    } catch (err) {
        const errorMsg = err instanceof Error ? err.message : String(err);
        const errorStack = err instanceof Error ? err.stack : undefined;
        
        if (Logger?.error) {
            Logger.error('[SuperSoaker.HTTP]', 'Unhandled middleware error:', errorMsg);
            if (errorStack && Logger?.debug) {
                Logger.debug('[SuperSoaker.HTTP]', 'Error stack:', errorStack);
            }
        }
        
        ctx.status = 500;
        ctx.body = { success: false, error: 'Internal server error' };
    }
});

app.use(koaBody({
        patchKoa: true,
        multipart: true,
    }))
   .use(router.routes())
   .use(router.allowedMethods());

setHttpCallback((req, res) => {
    console.log(`[SuperSoaker.HTTP] setHttpCallback invoked - URL: ${req.url}, Method: ${req.method}`);
    if (Logger?.debug) {
        Logger.debug('[SuperSoaker.HTTP]', 'setHttpCallback invoked', `URL: ${req.url}`, `Method: ${req.method}`);
    }
    return app.callback()(req, res);
});

//=-- Confirm HTTP server loaded
if (Logger?.info) {
    Logger.info('[Medal SuperSoaker.HTTP]', 'HTTP server initialized for screenshot uploads');
} else {
    console.log('[Medal SuperSoaker.HTTP] HTTP server initialized for screenshot uploads');
}

//=-- Export for Lua to register upload callbacks
const exp = (<any>global).exports;

exp('registerUpload', (token: string, playerSrc: number, cb: (err: string | boolean, data: string) => void) => {
    try {
        //=-- Debug log received parameters
        if (Logger?.debug) {
            Logger.debug('[SuperSoaker.Server]', 'registerUpload called', `token type: ${typeof token}`, `playerSrc type: ${typeof playerSrc}`, `playerSrc value: ${playerSrc}`, `cb type: ${typeof cb}`);
        }
        
        if (!token || typeof token !== 'string') {
            const error = 'Invalid token provided to registerUpload';
            if (Logger?.error) {
                Logger.error('[SuperSoaker.Server]', error, `Token: ${token}`);
            }
            throw new Error(error);
        }
        
        if (typeof playerSrc !== 'number') {
            const error = 'Invalid playerSrc provided to registerUpload';
            if (Logger?.error) {
                Logger.error('[SuperSoaker.Server]', error, `PlayerSrc type: ${typeof playerSrc}`, `PlayerSrc value: ${playerSrc}`);
            }
            throw new Error(error);
        }
        
        if (typeof cb !== 'function') {
            const error = 'Invalid callback provided to registerUpload';
            if (Logger?.error) {
                Logger.error('[SuperSoaker.Server]', error, `Callback type: ${typeof cb}`);
            }
            throw new Error(error);
        }
        
        uploads[token] = {
            playerSrc,
            cb
        };
        
        if (Logger?.debug) {
            Logger.debug('[SuperSoaker.Server]', 'Registered upload token', `Token: ${token}`, `PlayerSrc: ${playerSrc}`);
        }
    } catch (err) {
        const errorMsg = err instanceof Error ? err.message : String(err);
        if (Logger?.error) {
            Logger.error('[SuperSoaker.Server]', 'Error in registerUpload:', errorMsg);
        }
        throw err;
    }
});

exp('generateToken', () => {
    try {
        const token = v4();
        if (Logger?.debug) {
            Logger.debug('[SuperSoaker.Server]', 'Generated token', `Token: ${token}`);
        }
        return token;
    } catch (err) {
        const errorMsg = err instanceof Error ? err.message : String(err);
        if (Logger?.error) {
            Logger.error('[SuperSoaker.Server]', 'Error generating token:', errorMsg);
        }
        throw err;
    }
});
