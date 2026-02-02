import { Variants } from 'framer-motion';

/**
 * Spring animation configuration
 */
export const spring = {
  type: 'spring' as const,
  stiffness: 300,
  damping: 30,
};

/**
 * Fade in from bottom animation
 */
export const fadeInUp: Variants = {
  initial: { opacity: 0, y: 20 },
  animate: { opacity: 1, y: 0 },
  exit: { opacity: 0, y: 20 },
};

/**
 * Container for staggered children animations
 */
export const staggerContainer: Variants = {
  animate: {
    transition: {
      staggerChildren: 0.1,
    },
  },
};

/**
 * Shimmer effect for updated values
 */
export const shimmerVariants: Variants = {
  initial: { opacity: 0.5 },
  animate: {
    opacity: [0.5, 1, 0.5],
    transition: { duration: 0.6 },
  },
};

/**
 * Stagger children with fade in
 */
export const containerVariants: Variants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1,
    },
  },
};

/**
 * Individual item fade in (for use with containerVariants)
 */
export const itemVariants: Variants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0 },
};
