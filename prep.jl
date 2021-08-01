module Prep

# add JSON
import JSON

function run()
sql = open("./perf.sql"; create=true, truncate=true);
json = JSON.parse(open("./perf.json"))
for message in json["messages"]
  for op in message["ops"]
    if (op["op"] in ["insert", "delete"])
      # op looks like {"time":1460464810735,"node":0,"seq":10,"ops":[{"id":"11-0","op":"insert","ref":"10-0","val":"t"}]}
      id = split(op["id"], "-")[1]
      agent = split(op["id"], "-")[2]
      ref = get(op, "ref", nothing)
      ref_id = (ref != nothing) ? split(ref, "-")[1] : "null"
      ref_agent = (ref != nothing) ? split(ref, "-")[2] : "null"
      raw_value = get(op, "val", nothing);
      value = (raw_value == nothing) ? "null" : Int(raw_value[1])
      write(sql, "insert into edits values ($(id), $(agent), $(ref_id), $(ref_agent), $value);\n")
    end
  end
end
close(sql)
end

run()

end-