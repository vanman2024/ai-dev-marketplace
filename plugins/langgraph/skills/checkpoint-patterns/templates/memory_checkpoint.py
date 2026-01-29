# Memory checkpointer (development)
from langgraph.checkpoint.memory import MemorySaver

checkpointer = MemorySaver()
app = graph.compile(checkpointer=checkpointer)

# Use with thread_id
config = {"configurable": {"thread_id": "user-123"}}
result = app.invoke({"messages": []}, config)
