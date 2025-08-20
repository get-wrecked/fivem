import type React from 'react';

//=-- Centralized NUI message listeners for messages coming from Lua/CFX
//=-- This component registers event handlers via @tsfx/hooks and renders nothing
export const NuiHandlers: React.FC = () => {
    //=-- Ex: Add more handlers below as your server/client scripts emit events
    //=-- useNuiEvent<TypeGoesHere>('your:event:name', { handler: (payload) => { /*//=-- do thing */ } });

    return null;
};

export default NuiHandlers;
