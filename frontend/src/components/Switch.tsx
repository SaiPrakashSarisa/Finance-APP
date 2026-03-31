'use client';

interface SwitchProps {
    checked: boolean;
    onChange: (checked: boolean) => void;
    disabled?: boolean;
    label?: string;
}

export function Switch({ checked, onChange, disabled, label }: SwitchProps) {
    return (
        <label className={`flex items-center gap-3 cursor-pointer ${disabled ? 'opacity-50 cursor-not-allowed' : ''}`}>
            <div className="relative">
                <input
                    type="checkbox"
                    className="sr-only"
                    checked={checked}
                    onChange={(e) => !disabled && onChange(e.target.checked)}
                    disabled={disabled}
                />
                <div 
                    className={`w-11 h-6 rounded-full transition-colors duration-200 ease-in-out ${
                        checked ? 'bg-violet-500' : 'bg-slate-700'
                    }`}
                />
                <div 
                    className={`absolute left-1 top-1 bg-white w-4 h-4 rounded-full transition-transform duration-200 ease-in-out ${
                        checked ? 'translate-x-5' : 'translate-x-0'
                    }`}
                />
            </div>
            {label && <span className="text-sm font-medium text-slate-300">{label}</span>}
        </label>
    );
}
