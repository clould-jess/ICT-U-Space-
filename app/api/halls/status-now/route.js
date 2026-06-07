import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export const dynamic = 'force-dynamic';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET,OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, Cookie',
};

export async function OPTIONS() {
  return new Response(null, { status: 204, headers: corsHeaders });
}

/**
 * GET /api/halls/status-now
 * Returns ALL halls with their current occupancy status.
 * Each hall has:
 *   - occupied: boolean
 *   - current_subject: string | null  (course name if occupied by timetable)
 *   - current_time_slot: string | null  ("09:00 - 11:00")
 */
export async function GET() {
  try {
    const now = new Date();

    const currentDay = now.toLocaleDateString('en-US', { weekday: 'long' });
    const hh = now.getHours().toString().padStart(2, '0');
    const mm = now.getMinutes().toString().padStart(2, '0');
    const currentTime = `${hh}:${mm}`;

    const offset = now.getTimezoneOffset();
    const todayDate = new Date(now.getTime() - offset * 60 * 1000)
      .toISOString()
      .split('T')[0];

    const allHalls = await prisma.hall.findMany({ orderBy: { name: 'asc' } });

    const result = await Promise.all(
      allHalls.map(async (hall) => {
        // 1. Check timetable occupation
        const timetableEntry = await prisma.timetableEntry.findFirst({
          where: {
            hall_id: hall.id,
            day_of_week: currentDay,
            AND: [
              { start_time: { lte: currentTime } },
              { end_time: { gt: currentTime } },
            ],
          },
          include: { course: true },
        });

        if (timetableEntry) {
          return {
            ...hall,
            occupied: true,
            current_subject: timetableEntry.course?.name ?? 'Class in session',
            current_time_slot: `${timetableEntry.start_time} - ${timetableEntry.end_time}`,
          };
        }

        // 2. Check ad-hoc reservation occupation
        const reservation = await prisma.reservation.findFirst({
          where: {
            hall_id: hall.id,
            date: todayDate,
            status: 'CONFIRMED',
            AND: [
              { start_time: { lte: currentTime } },
              { end_time: { gt: currentTime } },
            ],
          },
          include: { course: true },
        });

        if (reservation) {
          const label = reservation.event_name
            ?? reservation.course?.name
            ?? 'Reserved';
          return {
            ...hall,
            occupied: true,
            current_subject: label,
            current_time_slot: `${reservation.start_time} - ${reservation.end_time}`,
          };
        }

        return {
          ...hall,
          occupied: false,
          current_subject: null,
          current_time_slot: null,
        };
      })
    );

    return new Response(JSON.stringify(result), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    console.error('Hall status-now error:', error);
    return new Response(
      JSON.stringify({ error: 'Internal Server Error' }),
      { status: 500, headers: corsHeaders }
    );
  }
}
