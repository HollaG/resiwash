import { useEffect, useMemo, useRef } from 'react';
import { differenceInMinutes, format } from 'date-fns';
import { MachineEvent, MachineStatus } from '../../types/datatypes';
import styles from './index.module.css';

const MARKER_SIZE_PX = 22;

function clampNumber(value: number, min: number, max: number) {
  return Math.min(max, Math.max(min, value));
}

function formatTime(timestamp: string | Date) {
  return format(new Date(timestamp), 'h:mm a').toLowerCase();
}

function formatDurationShort(minutesTotal: number) {
  const minutes = Math.max(0, Math.floor(minutesTotal));
  if (minutes >= 43200) return `${Math.floor(minutes / 43200)}m`; // 30d
  if (minutes >= 10080) return `${Math.floor(minutes / 10080)}w`; // 7d
  if (minutes >= 1440) return `${Math.floor(minutes / 1440)}d`; // 24h
  if (minutes >= 60) return `${Math.floor(minutes / 60)}h`;
  return `${minutes}m`;
}

function getStatusColor(status: MachineStatus) {
  switch (status) {
    case MachineStatus.AVAILABLE:
      return 'var(--color-status-available)';
    case MachineStatus.IN_USE:
      return 'var(--color-status-inUse)';
    case MachineStatus.FINISHING:
      return 'var(--color-status-finishing)';
    case MachineStatus.HAS_ISSUES:
      return 'var(--color-status-issues)';
    case MachineStatus.UNKNOWN:
    default:
      return 'var(--color-status-unknown)';
  }
}

function getSegmentWidthPx(from: string | Date, to: string | Date) {
  const minutes = Math.max(1, differenceInMinutes(new Date(to), new Date(from)));
  return clampNumber(Math.round(minutes * 1.25), 60, 280);
}

function TimelineMarker({ status }: { status: MachineStatus }) {
  const color = getStatusColor(status);

  if (status === MachineStatus.FINISHING) {
    return (
      <div
        className={styles.markerFinishing}
        style={{ borderColor: color }}
        aria-label="Finishing"
        role="img"
      />
    );
  }

  return (
    <div
      className={styles.marker}
      style={{ backgroundColor: color }}
      aria-label={status}
      role="img"
    />
  );
}

export const CustomTimeline = ({ events }: { events: MachineEvent[] }) => {
  const ref = useRef<HTMLDivElement>(null);

  const { pointsAsc, currentStatus } = useMemo(() => {
    const sortedDesc = [...(events ?? [])].sort(
      (a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()
    );

    return {
      pointsAsc: [...sortedDesc].reverse(),
      currentStatus: sortedDesc[0]?.status ?? MachineStatus.UNKNOWN,
    };
  }, [events]);

  useEffect(() => {
    if (ref.current) {
      ref.current.scrollLeft = ref.current.scrollWidth;
    }
  }, [pointsAsc.length]);

  if (!pointsAsc.length) {
    return <div>No events available</div>;
  }

  const now = new Date();
  const lastPoint = pointsAsc[pointsAsc.length - 1];

  const nowSegmentWidth = getSegmentWidthPx(lastPoint.timestamp, now);
  const nowSegmentMinutes = Math.max(
    0,
    differenceInMinutes(now, new Date(lastPoint.timestamp))
  );

  return (
    <div className={styles.timelineScrollContainer} ref={ref}>
      <div className={styles.timelineContainer} style={{ ['--marker-size' as any]: `${MARKER_SIZE_PX}px` }}>
        {pointsAsc.map((point, index) => {
          const previous = pointsAsc[index - 1];
          const segmentWidth = previous
            ? getSegmentWidthPx(previous.timestamp, point.timestamp)
            : null;

          return (
            <div key={`${point.eventId}-${point.timestamp}`} className={styles.timelineGroup}>
              {segmentWidth !== null && (
                <div
                  className={styles.segment}
                  style={{ width: `${segmentWidth}px`, backgroundColor: getStatusColor(previous.status) }}
                />
              )}

              <div className={styles.point}>
                <TimelineMarker status={point.status} />
                <div className={styles.timeLabel}>{formatTime(point.timestamp)}</div>
              </div>
            </div>
          );
        })}

        <div
          className={styles.segmentToNow}
          style={{ width: `${nowSegmentWidth}px`, backgroundColor: getStatusColor(currentStatus) }}
        >
          <div className={styles.durationLabel}>{formatDurationShort(nowSegmentMinutes)}</div>
        </div>

        <div className={styles.nowMarker}>
          <div
            className={styles.nowTick}
            style={{ backgroundColor: getStatusColor(currentStatus) }}
          />
          <div className={styles.nowTimeLabel}>{formatTime(now)}</div>
        </div>

      </div>
    </div>
  );
};
