import { useEffect } from 'react';

const ANDROID_APP_URL = 'https://play.google.com/store/apps/details?id=com.resiwash.app';
const IOS_APP_URL = 'https://apps.apple.com/sg/app/resiwash/id6760129310';

function isAndroidDevice(userAgent: string): boolean {
  return /android/i.test(userAgent);
}

function isIOSDevice(userAgent: string): boolean {
  const iOSUserAgent = /iPad|iPhone|iPod/i.test(userAgent);

  // Detect iPadOS, which can present itself as Mac but has touch support.
  const iPadOs =
    /Macintosh/i.test(userAgent) &&
    navigator.maxTouchPoints > 1;

  return iOSUserAgent || iPadOs;
}

export function AppRedirect() {
  useEffect(() => {
    const userAgent = navigator.userAgent || '';

    if (isAndroidDevice(userAgent)) {
      window.location.replace(ANDROID_APP_URL);
      return;
    }

    if (isIOSDevice(userAgent)) {
      window.location.replace(IOS_APP_URL);
      return;
    }

    window.location.replace('/');
  }, []);

  return null;
}