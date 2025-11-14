/*
  Medal.tv - FiveM Resource
  =========================
  File: ui/src/components/clip-length.tsx
  =====================
  Description:
    Clip length component for the UI
  ---
  Exports & Exported Components:
    - ClipLength: The clip length component
  ---
  Globals:
    None
*/

import { fetchNui } from '@tsfx/hooks';
import type React from 'react';
import { useTranslation } from 'react-i18next';
import { useClipLength } from '@/hooks/use-clip-length';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';

export const ClipLength: React.FC = () => {
    const { length, setLength } = useClipLength();
    const { t } = useTranslation();

    const updateLength = (value: string): void => {
        setLength(value);
        fetchNui('ac:length', { payload: value });
    };

    return (
        <div className='w-full h-9 flex items-center justify-between font-normal'>
            <span className='font-medium'>{t('clip_length.title')}</span>

            <Select value={length} onValueChange={updateLength}>
                <SelectTrigger className='w-32'>
                    <SelectValue />
                </SelectTrigger>
                <SelectContent>
                    <SelectItem value='15'>{t('clip_length.seconds', { count: 15 })}</SelectItem>
                    <SelectItem value='30'>{t('clip_length.seconds', { count: 30 })}</SelectItem>
                    <SelectItem value='1'>{t('clip_length.minutes', { count: 1 })}</SelectItem>
                    <SelectItem value='2'>{t('clip_length.minutes', { count: 2 })}</SelectItem>
                    <SelectItem value='3'>{t('clip_length.minutes', { count: 3 })}</SelectItem>
                    <SelectItem value='5'>{t('clip_length.minutes', { count: 5 })}</SelectItem>
                </SelectContent>
            </Select>
        </div>
    );
};
