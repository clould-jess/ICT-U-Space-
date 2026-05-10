import prisma from '../../../../lib/prisma';

export const dynamic = 'force-dynamic';

export async function GET() {
  try {
    const now = new Date();
    const currentDay = now.toLocaleDateString('en-US', { weekday: 'long' });
    const currentHours = now.getHours().toString().padStart(2, '0');
    const currentMinutes = now.getMinutes().toString().padStart(2, '0');
    const currentTimeStr = `${currentHours}:${currentMinutes}`;
    const offset = now.getTimezoneOffset();
    const todayDateStr = new Date(now.getTime() - (offset * 60 * 1000)).toISOString().split('T')[0];

    const allHalls = await prisma.hall.findMany();
    const result = [];

    for (const hall of allHalls) {
      const timetableNow = await prisma.timetableEntry.findFirst({
        where: {
          hall_id: hall.id,
          day_of_week: currentDay,
          AND: [{ start_time: { lte: currentTimeStr } }, { end_time: { gt: currentTimeStr } }]
        },
        include: { course: true }
      });

      const reservationNow = await prisma.reservation.findFirst({
        where: {
          hall_id: hall.id,
          date: todayDateStr,
          status: 'CONFIRMED',
          AND: [{ start_time: { lte: currentTimeStr } }, { end_time: { gt: currentTimeStr } }]
        },
        include: { course: true }
      });

      const nextTimetable = await prisma.timetableEntry.findFirst({
        where: {
          hall_id: hall.id,
          day_of_week: currentDay,
          start_time: { gt: currentTimeStr }
        },
        orderBy: { start_time: 'asc' },
        include: { course: true }
      });

      const busy = timetableNow || reservationNow;
      result.push({
        ...hall,
        status: busy ? 'busy' : 'free',
        currentActivity: busy ? (timetableNow || reservationNow) : null,
        nextClass: nextTimetable
      });
    }

    return new Response(JSON.stringify(result), { status: 200 });
  } catch (error) {
    console.error('Hall status error:', error);
    return new Response(JSON.stringify({ error: 'Internal Server Error' }), { status: 500 });
  }
}
