export default defineEventHandler(async (event) => listAddresses((await requireUser(event)).id))
