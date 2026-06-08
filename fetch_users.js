const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log("Connecting to live database at 109.199.115.217...");
  const users = await prisma.user.findMany({
    select: { id: true, name: true, email: true, role: true, matricule: true }
  });
  console.log("\nTotal Users:", users.length);
  console.table(users);
}

main()
  .catch(e => { console.error("Error fetching users:", e); process.exit(1); })
  .finally(async () => { await prisma.$disconnect(); });
