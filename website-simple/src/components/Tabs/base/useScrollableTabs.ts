// DEPRECATED DUE TO BAD UX

import { useEffect, useRef } from "react";
import { rafThrottle } from "../../../utils/rafThrottle";

const ACTIVE_TAB_SELECTOR = '[aria-selected="true"]';

const scrollToActiveTab = (
  element: HTMLDivElement | null,
  scrollIntoViewOptions?: ScrollIntoViewOptions
) => {
  const activeTab =
    element?.querySelector<HTMLButtonElement>(ACTIVE_TAB_SELECTOR);

  if (activeTab) {
    activeTab.scrollIntoView({
      behavior: "smooth",
      inline: "center",
      block: "nearest",
      ...scrollIntoViewOptions,
    });
  }
};

export const useScrollableTabs = () => {
  const tabListReference = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    // 1. Scroll immediately after mounting
    scrollToActiveTab(tabListReference.current, { behavior: "instant" });

    // 2. Scroll when active
    const observer = new MutationObserver(() => {
      scrollToActiveTab(tabListReference.current);
    });

    if (tabListReference.current) {
      observer.observe(tabListReference.current, {
        attributes: true,
        subtree: true,
      });
    }

    // 3. Add resize handler
    const throttledHandleResize = rafThrottle(() => {
      scrollToActiveTab(tabListReference.current);
    });

    window.addEventListener("resize", throttledHandleResize);

    return () => {
      observer.disconnect();
      window.removeEventListener("resize", throttledHandleResize);
    };
  }, []);

  return {
    tabListReference,
  };
};
