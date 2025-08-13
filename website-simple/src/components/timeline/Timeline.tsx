import { MachineEvent } from "../../types/datatypes";
import { getColorForMachineStatus } from "../../utils/colors";
import { StatusIndicator } from "../mini/StatusIndicator";
import { differenceInMilliseconds, endOfDay, format, isSameDay, startOfDay } from "date-fns";
import styles from "./index.module.css";
import { useEffect, useRef } from "react";
// should be sorted descending by createdAt
//

export const CustomTimeline = ({ events }: { events: MachineEvent[] }) => {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (ref.current) {
      ref.current.scrollLeft = ref.current.scrollWidth;
    }
  }, []);

  if (!events || events.length === 0) {
    return <div>No events available</div>;
  }

  const elements = events.flatMap((event, index) => {
    let laterEventTime = null;
    if (index > 0) {
      laterEventTime = events[index - 1].timestamp;
    } else {
      laterEventTime = new Date().toISOString(); // Use current time for the first event
    }

    // min width = 50 px
    // for every minute, add 1 px to the width
    // up to a max of 3 hours (12 * 25px = 300px)
    const timeDifference = new Date(laterEventTime).getTime() - new Date(event.timestamp).getTime();
    const timeInMinutes = Math.floor(timeDifference / 60000); // Convert to minutes
    console.log({ timeDifference, timeInMinutes })
    const width = Math.min(150, Math.max(80, timeInMinutes * 1.5)); // Ensure width is between 50px and 300px


    // if the previous event and current one crosses a day, need to add a TimelineSeparator
    if (!isSameDay(new Date(laterEventTime), new Date(event.timestamp))) {
      // left width is from laterEventTime to the start of the day of laterEventTime
      // right with is from the start of the day of laterEventTime to the current event, OR just timeDifference minus left time
      console.log({ laterEventTime, eventTimestamp: event.timestamp });
      const msSinceStartOfDay = differenceInMilliseconds(laterEventTime, startOfDay(new Date(laterEventTime)));
      const minutesSinceStartOfDay = Math.floor(msSinceStartOfDay / 60000); // left

      const msTillEndOfDay = differenceInMilliseconds(endOfDay(new Date(event.timestamp)), new Date(event.timestamp));
      const minutesTillEndOfDay = Math.floor(msTillEndOfDay / 60000); // right

      // note: (since start) + (till end) should equal timeDifference
      const leftWidth = Math.min(150, Math.max(40, minutesSinceStartOfDay * 1.5));
      const rightWidth = Math.min(150, Math.max(40, minutesTillEndOfDay * 1.5));

      // using the startOfDay(new Date(laterEventTime)), format the date as 8 May, 2 June, 15 July, etc
      const label = format(startOfDay(new Date(laterEventTime)), 'd MMM');

      return [
        <TimelineConnector key={`${index}-1`} event={event} width={leftWidth} />,
        <TimelineSeparator key={`${index}-2`} event={event} labelTop={label} />,
        <TimelineConnector key={`${index}-3`} event={event} width={rightWidth} />,
        <TimelineEvent key={`${index}-4`} event={event} />,
      ]



      // const leftWidth = (new Date(laterEventTime).setHours(0, 0, 0, 0) - new Date(event.timestamp).getTime()) / 60000 * 1.5;
      // const rightWidth = Math.max(0, width - leftWidth);
      // console.log({ leftWidth, rightWidth, width })
    } else {
      // first event
      // should add a time label
      // if > 60m show hours
      // if > 24h, show days
      // if > 7 days, show weeks
      // if > 30 days, show months
      let label = ''
      if (timeInMinutes > 60) {
        label = `${Math.floor(timeInMinutes / 60)}h`;
      } else if (timeInMinutes > 1440) { // 24 hours
        label = `${Math.floor(timeInMinutes / 1440)}d`;
      } else if (timeInMinutes > 10080) { // 7 days
        label = `${Math.floor(timeInMinutes / 10080)}w`;
      } else if (timeInMinutes > 43200) { // 30 days
        label = `${Math.floor(timeInMinutes / 43200)}m`;
      } else {
        label = `${timeInMinutes}m`;
      }

      // todo: if the first event was yesterday, it will not show the time label becuase it will be in the other if-block

      return [<TimelineConnector key={`${index}-1`} event={event} width={width} label={index === 0 ? label : undefined} />, <TimelineEvent key={`${index}-2`} event={event} />,];

    }


  })

  // SPECIAL: replace the first Timeline

  // add a TimelineSeparator at the start, with the label being "Now"
  elements.unshift(
    <TimelineSeparator key={`now`} event={events[0]} labelTop="Now" labelBottom={format(new Date(), 'h:mm aaa').toLowerCase()} />
  );

  // add a timelineSeparator at the end, with the label being the last event's startOfDay
  const lastEvent = events[events.length - 1];
  elements.push(
    ...[<TimelineConnector event={lastEvent} width={50} />, <TimelineSeparator key={`end`} event={lastEvent} labelTop={format(startOfDay(new Date(lastEvent.timestamp)), 'd MMM')} />]
  );

  return <div style={{ overflowX: 'auto' }} ref={ref}>
    <div className={styles.timelineContainer}>
      {elements}
    </div>
  </div>


}

const TimelineEvent = ({ event }: { event: MachineEvent }) => {
  const formatTime = (timestamp: string | Date) => {
    const date = new Date(timestamp);
    return format(date, 'h:mm aaa').toLowerCase();
  };

  return <div className={styles.timelineItem}>
    <StatusIndicator status={event.status} />
    <div className={`${styles.timelineLabel} ${styles.timelineLabelBottom}`} style={{ position: 'absolute' }}>{formatTime(event.timestamp)}</div>

  </div>
}

const TimelineConnector = ({ event, width, label }: { event: MachineEvent, width?: number, label?: string }) => {
  const color = getColorForMachineStatus(event.status);

  return <div className={styles.timelineConnectorContainer}>
    <div className={styles.timelineConnector} style={{ backgroundColor: color, width: `${width}px` }} />
    <div className={styles.timelineConnectorLabel}>{label}</div>
  </div>;
}

const TimelineSeparator = ({ event, labelTop, labelBottom }: { event: MachineEvent, labelTop?: string, labelBottom?: string }) => {
  const color = getColorForMachineStatus(event.status);
  return <div className={styles.timelineSeparatorContainer}>

    <div className={styles.timelineSeparator} style={{ backgroundColor: color }} />
    <div className={`${styles.timelineSeparatorLabel} ${styles.top}`}>{labelTop}</div>
    <div className={`${styles.timelineSeparatorLabel} ${styles.bottom}`}>{labelBottom}</div>
  </div>
};