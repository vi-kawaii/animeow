import { SQL } from "bun"
import { Elysia } from "elysia"

const connection_string = "postgres://postgres:admin@localhost:5432/main"

const sql = new SQL(connection_string)

let data = 0

new Elysia()
  .get("/counter", () => {
    return { m: `data is ${data++}` }
  })
  .post("/login", ({ params: { id, pw } }) => {
    console.log({ id, pw })

    const is_unique = true

    return { m: is_unique ? "" : "Your id is not unique" }
  })
  .listen(3000)
