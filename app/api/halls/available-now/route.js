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
    const availableHalls = [];

    for (const hall of allHalls) {
      const timetableConflicts = await prisma.timetableEntry.findMany({
        where: {
          hall_id: hall.id,
          day_of_week: currentDay,
          AND: [{ start_time: { lte: currentTimeStr } }, { end_time: { gt: currentTimeStr } }]
        }
      });

      const reservationConflicts = await prisma.reservation.findMany({
        where: {
          hall_id: hall.id,
          date: todayDateStr,
          status: 'CONFIRMED',
          AND: [{ start_time: { lte: currentTimeStr } }, { end_time: { gt: currentTimeStr } }]
        }
      });

      if (timetableConflicts.length === 0 && reservationConflicts.length === 0) {
        availableHalls.push(hall);
      }
    }

    if (availableHalls.length === 0) {
      return new Response(JSON.stringify({ error: 'No empty rooms available right now.' }), { status: 404 });
    }

    const randomHall = availableHalls[Math.floor(Math.random() * availableHalls.length)];
    return new Response(JSON.stringify(randomHall), { status: 200 });
  } catch (error) {
    console.error('Available Now API error:', error);
    return new Response(JSON.stringify({ error: 'Internal Server Error' }), { status: 500 });
  }
}
