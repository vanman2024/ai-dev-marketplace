# Basic LangGraph workflow
from langgraph.graph import StateGraph, START, END
from typing import TypedDict, Annotated
from operator import add

class State(TypedDict):
    messages: Annotated[list, add]

def process_node(state: State) -> dict:
    return {"messages": ["Processed"]}

graph = StateGraph(State)
graph.add_node("process", process_node)
graph.add_edge(START, "process")
graph.add_edge("process", END)

app = graph.compile()

if __name__ == "__main__":
    result = app.invoke({"messages": []})
    print(result)
