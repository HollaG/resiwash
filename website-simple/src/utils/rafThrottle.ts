export const rafThrottle = <T extends (...args: any[]) => void>(fn: T) => {
    let raf: number;

    return (...args: Parameters<T>) => {
        if (raf) {
            cancelAnimationFrame(raf);
        }

        raf = requestAnimationFrame(() => {
            fn(...args);
        });
    };
};