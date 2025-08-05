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
    const width = Math.min(150, Math.max(50, timeInMinutes * 1.5)); // Ensure width is between 50px and 300px


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
      const leftWidth = Math.min(150, Math.max(25, minutesSinceStartOfDay * 1.5));
      const rightWidth = Math.min(150, Math.max(25, minutesTillEndOfDay * 1.5));

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
      return [<TimelineConnector key={`${index}-1`} event={event} width={width} />, <TimelineEvent key={`${index}-2`} event={event} />,];

    }


  })

  // add a TimelineSeparator at the end, with the label being "Now"
  elements.unshift(
    <TimelineSeparator key={`now`} event={events[0]} labelTop="Now" labelBottom={format(new Date(), 'h:mm aaa').toLowerCase()} />
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

const TimelineConnector = ({ event, width }: { event: MachineEvent, width?: number }) => {
  const color = getColorForMachineStatus(event.status);

  return <div className={styles.timelineConnector} style={{ backgroundColor: color, width: `${width}px` }} />;
}

const TimelineSeparator = ({ event, labelTop, labelBottom }: { event: MachineEvent, labelTop?: string, labelBottom?: string }) => {
  const color = getColorForMachineStatus(event.status);
  return <div className={styles.timelineSeparatorContainer}>

    <div className={styles.timelineSeparator} style={{ backgroundColor: color }} />
    <div className={`${styles.timelineSeparatorLabel} ${styles.top}`}>{labelTop}</div>
    <div className={`${styles.timelineSeparatorLabel} ${styles.bottom}`}>{labelBottom}</div>
  </div>
};