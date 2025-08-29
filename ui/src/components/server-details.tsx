import { useServerDetails } from '@/hooks/use-server-details';

export const ServerDetails: React.FC = () => {
    const { name, iconUrl } = useServerDetails();

    return (
        <div className='w-full h-12 flex gap-2 items-center'>
            <img src={iconUrl} alt='Server Logo' className='size-12 rounded-lg' />
            <h4 className='line-clamp-2 font-medium'>{name}</h4>
        </div>
    );
};
