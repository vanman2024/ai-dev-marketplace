# Google Gemini API - Complete Guide for Agentic Capabilities & Agent Frameworks

**Last Updated:** November 9, 2025

## 📚 **Official Documentation Links**

### **Core Agentic Capabilities**

#### **Function Calling**

- [Function Calling Documentation](https://ai.google.dev/gemini-api/docs/function-calling)
- [Function Calling with Thinking](https://ai.google.dev/gemini-api/docs/function-calling#function_calling_with_thinking)
- [Parallel Function Calling](https://ai.google.dev/gemini-api/docs/function-calling#parallel_function_calling)
- [Compositional Function Calling](https://ai.google.dev/gemini-api/docs/function-calling#compositional_function_calling)
- [Function Calling Modes](https://ai.google.dev/gemini-api/docs/function-calling#function_calling_modes)
- [Automatic Function Calling (Python Only)](https://ai.google.dev/gemini-api/docs/function-calling#automatic_function_calling_python_only)
- [Multi-Tool Use](https://ai.google.dev/gemini-api/docs/function-calling#multi-tool_use)
- [Function Declarations](https://ai.google.dev/gemini-api/docs/function-calling#function_declarations)

#### **Model Context Protocol (MCP)**

- [Model Context Protocol Documentation](https://ai.google.dev/gemini-api/docs/function-calling#model_context_protocol_mcp)
- [MCP Official Website](https://modelcontextprotocol.io/introduction)
- [MCP SDK GitHub](https://github.com/modelcontextprotocol)

#### **Structured Output**

- [Structured Output Documentation](https://ai.google.dev/gemini-api/docs/structured-output)
- [JSON Mode](https://ai.google.dev/gemini-api/docs/structured-output#json-mode)

#### **Thinking & Reasoning**

- [Thinking Mode Documentation](https://ai.google.dev/gemini-api/docs/thinking)
- [Thought Signatures](https://ai.google.dev/gemini-api/docs/thinking#signatures)

### **Tools & Integrations**

#### **Native Tools**

- [Google Search Integration](https://ai.google.dev/gemini-api/docs/google-search)
- [Google Maps Grounding](https://ai.google.dev/gemini-api/docs/maps-grounding)
- [Code Execution](https://ai.google.dev/gemini-api/docs/code-execution)
- [URL Context](https://ai.google.dev/gemini-api/docs/url-context)
- [Computer Use](https://ai.google.dev/gemini-api/docs/computer-use)
- [File Search](https://ai.google.dev/gemini-api/docs/file-search)

#### **Live API (Streaming & Real-Time)**

- [Live API Overview](https://ai.google.dev/gemini-api/docs/live)
- [Live API Capabilities](https://ai.google.dev/gemini-api/docs/live-guide)
- [Live API Tool Use](https://ai.google.dev/gemini-api/docs/live-tools)
- [Session Management](https://ai.google.dev/gemini-api/docs/live-session)
- [Ephemeral Tokens](https://ai.google.dev/gemini-api/docs/ephemeral-tokens)

### **Agent Frameworks Integration**

#### **LangChain & LangGraph**

- [LangGraph with Gemini Documentation](https://ai.google.dev/gemini-api/docs/langgraph-example)
- [LangChain Python Docs](https://python.langchain.com/)
- [LangChain JavaScript Docs](https://js.langchain.com/)
- [LangGraph Documentation](https://langchain-ai.github.io/langgraph/)
- [LangChain GitHub](https://github.com/langchain-ai/langchain)
- [LangGraph GitHub](https://github.com/langchain-ai/langgraph)

#### **CrewAI**

- [CrewAI with Gemini Documentation](https://ai.google.dev/gemini-api/docs/crewai-example)
- [CrewAI Official Docs](https://docs.crewai.com/introduction)
- [CrewAI Concepts - Agents](https://docs.crewai.com/concepts/agents)
- [CrewAI Concepts - Tasks](https://docs.crewai.com/concepts/tasks)
- [CrewAI Concepts - Tools](https://docs.crewai.com/concepts/tools)
- [CrewAI GitHub](https://github.com/crewaiinc/crewai)
- [CrewAI Examples GitHub](https://github.com/crewaiinc/crewai-examples)

#### **LlamaIndex**

- [LlamaIndex Documentation](https://ai.google.dev/gemini-api/docs/llama-index)
- [LlamaIndex Official Docs](https://docs.llamaindex.ai/)
- [LlamaIndex Python GitHub](https://github.com/run-llama/llama_index)
- [LlamaIndex TypeScript GitHub](https://github.com/run-llama/llamaindexts)
- [LlamaCloud](https://cloud.llamaindex.ai/)

#### **Vercel AI SDK**

- [Vercel AI SDK with Gemini Documentation](https://ai.google.dev/gemini-api/docs/vercel-ai-sdk-example)
- [Vercel AI SDK Docs](https://sdk.vercel.ai/docs)
- [Vercel AI SDK GitHub](https://github.com/vercel/ai)

### **Advanced Guides**

- [Prompt Engineering Best Practices](https://ai.google.dev/gemini-api/docs/prompting-strategies)
- [Introduction to Prompt Design](https://ai.google.dev/gemini-api/docs/prompting-intro)
- [Context Caching](https://ai.google.dev/gemini-api/docs/caching)
- [Batch API](https://ai.google.dev/gemini-api/docs/batch-api)
- [Files API](https://ai.google.dev/gemini-api/docs/files)
- [Token Counting](https://ai.google.dev/gemini-api/docs/tokens)

### **Safety & Compliance**

- [Safety Settings](https://ai.google.dev/gemini-api/docs/safety-settings)
- [Data Logging and Sharing Policy](https://ai.google.dev/gemini-api/docs/logs-policy)
- [Logs and Datasets](https://ai.google.dev/gemini-api/docs/logs-datasets)

### **SDK Documentation**

- [Python GenAI SDK](https://googleapis.github.io/python-genai/)
- [Python GenAI GitHub](https://github.com/googleapis/python-genai)
- [Google Cloud Vertex AI](https://cloud.google.com/vertex-ai/docs)

### **Community & Support**

- [Gemini Cookbook](https://github.com/google-gemini/cookbook)
- [Community Forum](https://discuss.ai.google.dev/c/gemini-api/)
- [API Reference](https://ai.google.dev/api)
- [API Troubleshooting](https://ai.google.dev/gemini-api/docs/troubleshooting)

---

## 🤖 **Agentic Architecture Overview**

### **What Makes Gemini Agentic?**

Gemini's agentic capabilities enable AI models to:

1. **Take Actions**: Execute functions and interact with external systems
2. **Make Decisions**: Determine when and which tools to use
3. **Reason & Plan**: Use thinking mode for complex problem-solving
4. **Collaborate**: Work with multiple tools and frameworks simultaneously
5. **Iterate**: Support multi-turn conversations with context retention

---

## 🔧 **Function Calling - Core Agentic Capability**

### **What is Function Calling?**

Function calling lets models act as bridges between natural language and real-world actions. Instead of generating text, the model:

- Determines when to call functions
- Provides parameters to execute actions
- Processes results to continue conversations

### **Three Primary Use Cases**

1. **Augment Knowledge**: Access external databases, APIs, and knowledge bases
2. **Extend Capabilities**: Use tools for computations, create charts, process data
3. **Take Actions**: Interact with systems via APIs (schedule meetings, send emails, control devices)

### **How Function Calling Works**

```
┌─────────────────────────────────────────────────────────────┐
│  1. Define Function Declaration                              │
│     (Name, description, parameters)                          │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  2. Call LLM with Function Declarations + User Prompt       │
│     Model analyzes and decides if function call is needed   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  3. Model Returns:                                          │
│     • Function Call (name + args) OR                        │
│     • Direct Text Response                                  │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  4. Execute Function (Your Code)                            │
│     Extract name, args, execute function, capture result    │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  5. Send Result Back to Model                               │
│     Model generates user-friendly response with result      │
└─────────────────────────────────────────────────────────────┘
```

### **Python Example - Basic Function Calling**

```python
from google import genai
from google.genai import types

# Step 1: Define function declaration
schedule_meeting_function = {
    "name": "schedule_meeting",
    "description": "Schedules a meeting with specified attendees at a given time and date.",
    "parameters": {
        "type": "object",
        "properties": {
            "attendees": {
                "type": "array",
                "items": {"type": "string"},
                "description": "List of people attending the meeting.",
            },
            "date": {
                "type": "string",
                "description": "Date of the meeting (e.g., '2024-07-29')",
            },
            "time": {
                "type": "string",
                "description": "Time of the meeting (e.g., '15:00')",
            },
            "topic": {
                "type": "string",
                "description": "The subject or topic of the meeting.",
            },
        },
        "required": ["attendees", "date", "time", "topic"],
    },
}

# Step 2: Configure client and call model
client = genai.Client()
tools = types.Tool(function_declarations=[schedule_meeting_function])
config = types.GenerateContentConfig(tools=[tools])

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents="Schedule a meeting with Bob and Alice for 03/14/2025 at 10:00 AM about the Q3 planning.",
    config=config,
)

# Step 3: Check for function call
if response.candidates[0].content.parts[0].function_call:
    function_call = response.candidates[0].content.parts[0].function_call
    print(f"Function to call: {function_call.name}")
    print(f"Arguments: {function_call.args}")

    # Step 4: Execute function (your implementation)
    # result = schedule_meeting(**function_call.args)
else:
    print("No function call found")
    print(response.text)
```

### **Function Declaration Schema**

```python
function_declaration = {
    "name": "get_weather_forecast",  # Unique function name (use snake_case or camelCase)
    "description": "Gets the current weather temperature for a given location and date. Be specific and provide examples.",
    "parameters": {
        "type": "object",
        "properties": {
            "location": {
                "type": "string",  # string, integer, boolean, array
                "description": "The city and state, e.g., 'San Francisco, CA' or zip code '95616'"
            },
            "date": {
                "type": "string",
                "description": "Date for forecast (yyyy-mm-dd format)"
            },
            "unit": {
                "type": "string",
                "enum": ["celsius", "fahrenheit"],  # Use enum for fixed sets
                "description": "Temperature unit"
            }
        },
        "required": ["location", "date"]  # Mandatory parameters
    }
}
```

---

## 🔀 **Parallel Function Calling**

Execute multiple independent functions simultaneously.

### **Use Cases**

- Gathering data from multiple sources
- Checking inventory across warehouses
- Performing multiple independent actions

### **Example**

```python
from google import genai
from google.genai import types

# Define multiple functions
power_disco_ball = {
    "name": "power_disco_ball",
    "description": "Powers the spinning disco ball.",
    "parameters": {
        "type": "object",
        "properties": {
            "power": {"type": "boolean", "description": "Turn on or off"}
        },
        "required": ["power"],
    },
}

start_music = {
    "name": "start_music",
    "description": "Play music matching parameters.",
    "parameters": {
        "type": "object",
        "properties": {
            "energetic": {"type": "boolean"},
            "loud": {"type": "boolean"},
        },
        "required": ["energetic", "loud"],
    },
}

dim_lights = {
    "name": "dim_lights",
    "description": "Dim the lights.",
    "parameters": {
        "type": "object",
        "properties": {
            "brightness": {"type": "number", "description": "0.0 is off, 1.0 is full"}
        },
        "required": ["brightness"],
    },
}

# Configure for parallel calling
client = genai.Client()
house_tools = [types.Tool(function_declarations=[power_disco_ball, start_music, dim_lights])]

config = types.GenerateContentConfig(
    tools=house_tools,
    automatic_function_calling=types.AutomaticFunctionCallingConfig(disable=True),
    tool_config=types.ToolConfig(
        function_calling_config=types.FunctionCallingConfig(mode='ANY')  # Force function calls
    ),
)

chat = client.chats.create(model="gemini-2.5-flash", config=config)
response = chat.send_message("Turn this place into a party!")

# Print all function calls requested
for fn in response.function_calls:
    args = ", ".join(f"{key}={val}" for key, val in fn.args.items())
    print(f"{fn.name}({args})")
```

**Output:**

```
power_disco_ball(power=True)
start_music(energetic=True, loud=True)
dim_lights(brightness=0.5)
```

---

## 🔗 **Compositional Function Calling**

Chain multiple function calls sequentially to fulfill complex requests.

### **Example: Get Weather in Current Location**

```python
import os
from google import genai
from google.genai import types

def get_weather_forecast(location: str) -> dict:
    """Gets the current weather temperature for a given location."""
    print(f"Tool Call: get_weather_forecast(location={location})")
    return {"temperature": 25, "unit": "celsius"}

def set_thermostat_temperature(temperature: int) -> dict:
    """Sets the thermostat to a desired temperature."""
    print(f"Tool Call: set_thermostat_temperature(temperature={temperature})")
    return {"status": "success"}

# Configure client
client = genai.Client()
config = types.GenerateContentConfig(
    tools=[get_weather_forecast, set_thermostat_temperature]
)

# Make request - model will chain functions
response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents="If it's warmer than 20°C in London, set the thermostat to 20°C, otherwise set it to 18°C.",
    config=config,
)

print(response.text)
```

**Expected Output:**

```
Tool Call: get_weather_forecast(location=London)
Tool Response: {'temperature': 25, 'unit': 'celsius'}
Tool Call: set_thermostat_temperature(temperature=20)
Tool Response: {'status': 'success'}
OK. I've set the thermostat to 20°C.
```

---

## 🎛️ **Function Calling Modes**

Control how the model uses provided tools:

| Mode                    | Description                                                | Use Case                                          |
| ----------------------- | ---------------------------------------------------------- | ------------------------------------------------- |
| **AUTO** (Default)      | Model decides whether to call function or respond directly | Most flexible, recommended for most scenarios     |
| **ANY**                 | Model must predict a function call (guaranteed)            | Require function call for every prompt            |
| **NONE**                | Prohibit function calls                                    | Temporarily disable without removing declarations |
| **VALIDATED** (Preview) | Predict function or text, ensures schema adherence         | Balance between AUTO and ANY                      |

### **Configuration Example**

```python
from google.genai import types

# Force function calling from specific functions
tool_config = types.ToolConfig(
    function_calling_config=types.FunctionCallingConfig(
        mode="ANY",
        allowed_function_names=["get_current_temperature"]
    )
)

config = types.GenerateContentConfig(
    tools=[tools],
    tool_config=tool_config,
)
```

---

## 🤖 **Automatic Function Calling (Python SDK Only)**

The Python SDK can automatically execute functions and manage the call/response cycle.

### **Benefits**

- ✅ Automatically converts Python functions to declarations
- ✅ Detects function call responses
- ✅ Executes Python functions
- ✅ Sends results back to model
- ✅ Returns final text response

### **Example**

```python
from google import genai
from google.genai import types

# Define function with type hints and docstring
def get_current_temperature(location: str) -> dict:
    """Gets the current temperature for a given location.

    Args:
        location: The city and state, e.g. San Francisco, CA

    Returns:
        A dictionary containing the temperature and unit.
    """
    # ... implementation ...
    return {"temperature": 25, "unit": "Celsius"}

# Configure client with automatic calling
client = genai.Client()
config = types.GenerateContentConfig(
    tools=[get_current_temperature]  # Pass function directly!
)

# SDK handles everything automatically
response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents="What's the temperature in Boston?",
    config=config,
)

print(response.text)  # Final user-friendly response
```

### **Disable Automatic Function Calling**

```python
config = types.GenerateContentConfig(
    tools=[get_current_temperature],
    automatic_function_calling=types.AutomaticFunctionCallingConfig(disable=True)
)
```

---

## 🌐 **Model Context Protocol (MCP) Integration**

MCP is an open standard for connecting AI applications with external tools and data.

### **What is MCP?**

- **Open Standard**: Common protocol for models to access context
- **Components**: Functions (tools), Data sources (resources), Prompts
- **Built-in SDK Support**: Automatic tool calling for MCP tools

### **Example with MCP Server**

```python
import os
import asyncio
from datetime import datetime
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client
from google import genai

client = genai.Client()

# Create server parameters
server_params = StdioServerParameters(
    command="npx",
    args=["-y", "@philschmid/weather-mcp"],
    env=None,
)

async def run():
    async with stdio_client(server_params) as (read, write):
        async with ClientSession(read, write) as session:
            prompt = f"What is the weather in London in {datetime.now().strftime('%Y-%m-%d')}?"

            await session.initialize()

            # Send request with MCP session as tool
            response = await client.aio.models.generate_content(
                model="gemini-2.5-flash",
                contents=prompt,
                config=genai.types.GenerateContentConfig(
                    temperature=0,
                    tools=[session],  # MCP session as tool!
                ),
            )
            print(response.text)

asyncio.run(run())
```

### **MCP Limitations**

- ❌ Only tools supported (not resources or prompts)
- ❌ Python and JavaScript/TypeScript SDKs only
- ⚠️ Experimental feature, breaking changes possible

### **MCP Resources**

- [MCP Official Site](https://modelcontextprotocol.io/introduction)
- [MCP SDK Installation](https://modelcontextprotocol.io/introduction): `pip install mcp`

---

## 🧠 **Function Calling with Thinking Mode**

Enable reasoning before function calls for improved performance.

### **How It Works**

1. Model reasons through request (thinking)
2. Suggests function calls based on reasoning
3. **Thought signatures** preserve context across turns

### **Thought Signatures**

- Encrypted representation of model's thought process
- Automatically included in `content` object
- Preserved when appending complete previous response

### **Manual Management Rules**

```python
# Rule 1: Always send thought_signature inside original Part
# Rule 2: Don't merge Part with signature and Part without
# Rule 3: Don't combine two Parts with signatures
```

### **Inspecting Thought Signatures**

```python
import base64

# After receiving response with thinking enabled
part = response.candidates[0].content.parts[0]
if part.thought_signature:
    print(base64.b64encode(part.thought_signature).decode("utf-8"))
```

### **Learn More**

- [Thinking Documentation](https://ai.google.dev/gemini-api/docs/thinking)
- [Thought Signatures](https://ai.google.dev/gemini-api/docs/thinking#signatures)

---

## 🔄 **Multi-Tool Use**

Combine native tools with function calling simultaneously.

### **Example: Google Search + Code Execution + Custom Functions**

```python
# Multiple tasks example with Live API
prompt = """
Hey, I need you to do three things:
1. Turn on the lights.
2. Compute the largest prime palindrome under 100000.
3. Use Google Search for largest earthquake in California Dec 5, 2024.
"""

tools = [
    {'google_search': {}},
    {'code_execution': {}},
    {'function_declarations': [turn_on_lights_schema, turn_off_lights_schema]}
]

# Execute with Live API
await run(prompt, tools=tools, modality="AUDIO")
```

### **Supported Native Tools**

- ✅ Google Search (grounding)
- ✅ Code Execution
- ✅ Google Maps
- ✅ Function Calling

---

## 🏗️ **Agent Framework Integrations**

### **LangGraph with Gemini**

LangGraph is a framework for building stateful LLM applications.

#### **Core Concepts**

- **State**: Shared data structure (TypedDict or Pydantic)
- **Nodes**: Agent logic (LLM calls, tool calls)
- **Edges**: Control flow (conditional or fixed transitions)

#### **Complete Weather Agent Example**

```python
from typing import Annotated, Sequence, TypedDict
from langchain_core.messages import BaseMessage
from langgraph.graph.message import add_messages
from langgraph.graph import StateGraph, END
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.tools import tool
import os

# 1. Define State
class AgentState(TypedDict):
    """The state of the agent."""
    messages: Annotated[Sequence[BaseMessage], add_messages]
    number_of_steps: int

# 2. Define Tool
@tool("get_weather_forecast")
def get_weather_forecast(location: str, date: str):
    """Retrieves weather for a location and date (yyyy-mm-dd)."""
    # ... implementation ...
    return {"temperature": 25, "conditions": "sunny"}

tools = [get_weather_forecast]

# 3. Initialize Model
llm = ChatGoogleGenerativeAI(
    model="gemini-2.5-pro",
    temperature=1.0,
    google_api_key=os.getenv("GEMINI_API_KEY"),
)
model = llm.bind_tools([get_weather_forecast])

# 4. Define Nodes
def call_model(state: AgentState, config):
    response = model.invoke(state["messages"], config)
    return {"messages": [response]}

def call_tool(state: AgentState):
    outputs = []
    for tool_call in state["messages"][-1].tool_calls:
        tool_result = tools_by_name[tool_call["name"]].invoke(tool_call["args"])
        outputs.append(ToolMessage(
            content=tool_result,
            name=tool_call["name"],
            tool_call_id=tool_call["id"],
        ))
    return {"messages": outputs}

# 5. Define Conditional Edge
def should_continue(state: AgentState):
    if not state["messages"][-1].tool_calls:
        return "end"
    return "continue"

# 6. Build Graph
workflow = StateGraph(AgentState)
workflow.add_node("llm", call_model)
workflow.add_node("tools", call_tool)
workflow.set_entry_point("llm")
workflow.add_conditional_edges(
    "llm",
    should_continue,
    {"continue": "tools", "end": END},
)
workflow.add_edge("tools", "llm")

graph = workflow.compile()

# 7. Run Agent
from datetime import datetime

inputs = {"messages": [("user", f"What is the weather in Berlin on {datetime.today()}?")]}
for state in graph.stream(inputs, stream_mode="values"):
    last_message = state["messages"][-1]
    last_message.pretty_print()
```

#### **LangGraph Resources**

- [LangGraph Documentation](https://langchain-ai.github.io/langgraph/)
- [LangGraph Gemini Example](https://ai.google.dev/gemini-api/docs/langgraph-example)
- [LangGraph GitHub](https://github.com/langchain-ai/langgraph)
- [Create React Agent Prebuilt](https://langchain-ai.github.io/langgraph/reference/prebuilt/#langgraph.prebuilt.chat_agent_executor.create_react_agent)

---

### **CrewAI with Gemini**

CrewAI orchestrates autonomous AI agents that collaborate to achieve complex goals.

#### **Core Components**

1. **Tools**: Capabilities agents use to interact
2. **Agents**: Individual AI workers with roles
3. **Tasks**: Specific assignments for agents
4. **Crew**: Brings agents and tasks together

#### **Complete Customer Support Analysis Example**

```python
import os
from crewai import Agent, Task, Crew, Process, LLM
from crewai.tools import BaseTool

# 1. Initialize Gemini Model
gemini_llm = LLM(
    model='gemini/gemini-2.5-pro',
    api_key=os.getenv("GEMINI_API_KEY"),
    temperature=0.0
)

# 2. Define Tool
class CustomerSupportDataTool(BaseTool):
    name: str = "Customer Support Data Fetcher"
    description: str = "Fetches recent customer support interactions"

    def _run(self, argument: str) -> str:
        # ... fetch data implementation ...
        return """Support Data Summary:
        - 50 tickets for 'login issues' (avg 48h resolution)
        - 30 tickets for 'billing discrepancies' (avg 12h resolution)
        - Frequent 'confusing UI' feedback"""

support_data_tool = CustomerSupportDataTool()

# 3. Define Agents
data_analyst = Agent(
    role='Customer Support Data Analyst',
    goal='Analyze support data to identify trends and pain points.',
    backstory='Expert analyst specializing in customer support operations.',
    verbose=True,
    allow_delegation=False,
    tools=[support_data_tool],
    llm=gemini_llm
)

process_optimizer = Agent(
    role='Process Optimization Specialist',
    goal='Identify bottlenecks and propose improvements.',
    backstory='Specialist in optimizing business processes.',
    verbose=True,
    allow_delegation=False,
    llm=gemini_llm
)

report_writer = Agent(
    role='Executive Report Writer',
    goal='Compile analysis into concise COO report.',
    backstory='Skilled executive summary writer.',
    verbose=True,
    allow_delegation=False,
    llm=gemini_llm
)

# 4. Define Tasks
analysis_task = Task(
    description="""Fetch and analyze last quarter support data.
    Identify top 3-5 recurring issues with frequency.""",
    expected_output="""Summary with:
    - Top issues with frequency
    - Average resolution times
    - Key pain points""",
    agent=data_analyst
)

optimization_task = Task(
    description="""Identify bottlenecks from analysis.
    Propose 2-3 concrete improvements.""",
    expected_output="""List of bottlenecks and 2-3 specific recommendations.""",
    agent=process_optimizer
)

report_task = Task(
    description="""Compile findings into executive report for COO.""",
    expected_output="""Well-structured report (max 1 page) with issues,
    bottlenecks, and recommendations.""",
    agent=report_writer
)

# 5. Create Crew
support_analysis_crew = Crew(
    agents=[data_analyst, process_optimizer, report_writer],
    tasks=[analysis_task, optimization_task, report_task],
    process=Process.sequential,
    verbose=True
)

# 6. Run Crew
result = support_analysis_crew.kickoff(
    inputs={'data_query': 'last quarter support data'}
)
print(result)
```

#### **CrewAI Resources**

- [CrewAI Documentation](https://docs.crewai.com/introduction)
- [CrewAI with Gemini Example](https://ai.google.dev/gemini-api/docs/crewai-example)
- [CrewAI Agents Guide](https://docs.crewai.com/concepts/agents)
- [CrewAI Tasks Guide](https://docs.crewai.com/concepts/tasks)
- [CrewAI Tools Guide](https://docs.crewai.com/concepts/tools)
- [CrewAI GitHub](https://github.com/crewaiinc/crewai)

---

### **LlamaIndex with Gemini**

LlamaIndex is a data framework for building LLM applications specializing in RAG and agentic workflows.

#### **Key Features**

- Data ingestion and indexing
- Advanced document parsing
- Structured data extraction
- Agentic RAG workflows
- Multi-document agents

#### **Installation**

```bash
pip install llama-index-llms-gemini
pip install llama-index
```

#### **Basic Example**

```python
from llama_index.llms.gemini import Gemini
from llama_index.core.agent import ReActAgent
from llama_index.core.tools import FunctionTool
import os

# Initialize Gemini
llm = Gemini(
    model="models/gemini-2.5-pro",
    api_key=os.getenv("GEMINI_API_KEY")
)

# Define tools
def multiply(a: float, b: float) -> float:
    """Multiply two numbers"""
    return a * b

def add(a: float, b: float) -> float:
    """Add two numbers"""
    return a + b

multiply_tool = FunctionTool.from_defaults(fn=multiply)
add_tool = FunctionTool.from_defaults(fn=add)

# Create agent
agent = ReActAgent.from_tools(
    [multiply_tool, add_tool],
    llm=llm,
    verbose=True
)

# Run agent
response = agent.chat("What is (5 * 3) + 7?")
print(response)
```

#### **LlamaIndex Resources**

- [LlamaIndex Documentation](https://docs.llamaindex.ai/)
- [LlamaIndex with Gemini Guide](https://ai.google.dev/gemini-api/docs/llama-index)
- [LlamaIndex Python GitHub](https://github.com/run-llama/llama_index)
- [LlamaIndex TypeScript GitHub](https://github.com/run-llama/llamaindexts)
- [LlamaCloud](https://cloud.llamaindex.ai/)

---

### **Vercel AI SDK with Gemini**

Build AI-powered applications with React, Next.js, Vue, and more.

#### **Key Features**

- Streaming responses
- Tool calling support
- Multi-modal support
- Framework agnostic
- Edge runtime compatible

#### **Installation**

```bash
npm install ai @ai-sdk/google
```

#### **Example with Tools**

```typescript
import { generateText, tool } from 'ai';
import { google } from '@ai-sdk/google';
import { z } from 'zod';

const result = await generateText({
  model: google('gemini-2.5-flash'),
  tools: {
    weather: tool({
      description: 'Get the weather in a location',
      parameters: z.object({
        location: z.string().describe('The location to get weather for'),
      }),
      execute: async ({ location }) => ({
        location,
        temperature: 72 + Math.floor(Math.random() * 21) - 10,
      }),
    }),
  },
  prompt: 'What is the weather in San Francisco?',
});

console.log(result.text);
```

#### **Vercel AI SDK Resources**

- [Vercel AI SDK Documentation](https://sdk.vercel.ai/docs)
- [Vercel AI SDK with Gemini Guide](https://ai.google.dev/gemini-api/docs/vercel-ai-sdk-example)
- [Vercel AI SDK GitHub](https://github.com/vercel/ai)

---

## 📊 **Supported Models & Capabilities**

| Model                     | Function Calling | Parallel Calling | Compositional | Thinking |
| ------------------------- | ---------------- | ---------------- | ------------- | -------- |
| **Gemini 2.5 Pro**        | ✔️               | ✔️               | ✔️            | ✔️       |
| **Gemini 2.5 Flash**      | ✔️               | ✔️               | ✔️            | ✔️       |
| **Gemini 2.5 Flash-Lite** | ✔️               | ✔️               | ✔️            | ✔️       |
| **Gemini 2.0 Flash**      | ✔️               | ✔️               | ✔️            | ✔️       |
| **Gemini 2.0 Flash-Lite** | ❌               | ❌               | ❌            | ❌       |

---

## 🎯 **Best Practices for Agent Development**

### **Function & Parameter Descriptions**

- ✅ Be extremely clear and specific
- ✅ Model relies on descriptions to choose functions
- ✅ Provide examples in descriptions

### **Naming Conventions**

- ✅ Use descriptive names (snake_case or camelCase)
- ❌ Avoid spaces, periods, or dashes

### **Strong Typing**

- ✅ Use specific types (integer, string, enum)
- ✅ Use `enum` for limited value sets
- ✅ Reduces errors and improves accuracy

### **Tool Selection**

- ✅ Provide only relevant tools (max 10-20 recommended)
- ✅ Consider dynamic tool selection based on context
- ⚠️ Too many tools increases risk of wrong selection

### **Prompt Engineering for Agents**

```python
system_prompt = """
You are a helpful weather assistant.

GUIDELINES:
- Always use the get_weather_forecast tool for weather queries
- Don't guess dates; always use a future date for forecasts
- Ask clarifying questions if location is ambiguous
- Provide temperature in user's preferred unit

AVAILABLE TOOLS:
- get_weather_forecast: Gets weather for location and date
"""
```

### **Temperature Settings**

- ✅ Use low temperature (0-0.2) for deterministic function calls
- ✅ Higher temperature (0.7-1.0) for creative responses

### **Validation**

- ✅ Validate function calls before executing (especially for critical actions)
- ✅ Ask user confirmation for significant consequences

### **Error Handling**

```python
def execute_function_safely(function_name: str, args: dict):
    """Execute function with error handling"""
    try:
        result = functions[function_name](**args)
        return {"success": True, "result": result}
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "message": f"Failed to execute {function_name}"
        }
```

### **Check Finish Reason**

```python
from google.genai import types

response = client.models.generate_content(...)

# Always check finish reason
finish_reason = response.candidates[0].finish_reason
if finish_reason != types.FinishReason.STOP:
    print(f"Generation stopped due to: {finish_reason}")
```

### **Security Considerations**

- ✅ Use proper authentication/authorization for external APIs
- ✅ Validate and sanitize function inputs
- ✅ Avoid exposing sensitive data in function calls
- ✅ Implement rate limiting for external API calls

### **Token Limits**

- ⚠️ Function descriptions count toward input token limit
- ✅ Keep descriptions concise but informative
- ✅ Break complex tasks into smaller function sets

---

## 💡 **Advanced Agent Patterns**

### **ReAct Pattern (Reasoning and Acting)**

```
Thought: I need to find the weather in the user's current location
Action: get_current_location()
Observation: User is in San Francisco, CA
Thought: Now I have the location, I can get the weather
Action: get_weather_forecast("San Francisco, CA", "2024-03-14")
Observation: Temperature is 72°F, sunny
Thought: I have all the information to respond
Response: It's a beautiful day in San Francisco with 72°F and sunny skies!
```

### **Plan-Execute Pattern**

```python
# 1. Planning Phase
plan = agent.create_plan("Book a trip to Paris")
# Output: [
#   "Search for flights to Paris",
#   "Find hotels in Paris city center",
#   "Create itinerary for 3 days",
#   "Book selected flight and hotel"
# ]

# 2. Execution Phase
for step in plan:
    result = agent.execute_step(step)
    if not result.success:
        plan = agent.replan(plan, step, result.error)
```

### **Multi-Agent Collaboration**

```python
# Specialist agents
research_agent = Agent(role="Researcher", tools=[web_search, read_document])
writer_agent = Agent(role="Writer", tools=[write_document, edit_text])
editor_agent = Agent(role="Editor", tools=[review_text, suggest_edits])

# Workflow
research = research_agent.execute("Research AI trends")
draft = writer_agent.execute(f"Write article about: {research}")
final = editor_agent.execute(f"Edit and finalize: {draft}")
```

---

## 📦 **Installation Quick Reference**

### **Python SDK**

```bash
pip install google-genai
```

### **Agent Frameworks**

```bash
# LangChain & LangGraph
pip install langgraph langchain-google-genai

# CrewAI
pip install "crewai[tools]"

# LlamaIndex
pip install llama-index-llms-gemini llama-index

# MCP
pip install mcp
```

### **JavaScript/TypeScript**

```bash
# Vercel AI SDK
npm install ai @ai-sdk/google

# LangChain.js
npm install langchain @langchain/google-genai
```

---

## 🔐 **Authentication & Setup**

### **Get API Key**

Visit [Google AI Studio](https://aistudio.google.com/apikey) to get your API key.

### **Set Environment Variable**

**Linux/Mac:**

```bash
export GEMINI_API_KEY='your-api-key-here'
```

**Windows (PowerShell):**

```powershell
$env:GEMINI_API_KEY='your-api-key-here'
```

**Python:**

```python
import os
os.environ['GEMINI_API_KEY'] = 'your-api-key-here'
```

### **Initialize Client**

**Python (Developer API):**

```python
from google import genai

client = genai.Client(api_key=os.getenv('GEMINI_API_KEY'))
```

**Python (Vertex AI):**

```python
from google import genai

client = genai.Client(
    vertexai=True,
    project='my-project-id',
    location='us-central1'
)
```

---

## 🚀 **Quick Start Examples**

### **Simple Function Calling**

```python
from google import genai
import os

client = genai.Client(api_key=os.getenv('GEMINI_API_KEY'))

# Define function
def calculator(operation: str, a: float, b: float) -> float:
    """Perform basic math operations."""
    if operation == "add": return a + b
    elif operation == "subtract": return a - b
    elif operation == "multiply": return a * b
    elif operation == "divide": return a / b

# Use automatic function calling
response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents="What is 15 multiplied by 7?",
    config={"tools": [calculator]}
)

print(response.text)
```

### **LangGraph Agent**

```python
from langgraph.prebuilt import create_react_agent
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.tools import tool

@tool
def get_weather(location: str) -> str:
    """Get weather for location."""
    return f"It's sunny in {location}"

llm = ChatGoogleGenerativeAI(model="gemini-2.5-pro")
agent = create_react_agent(llm, tools=[get_weather])

result = agent.invoke({"messages": [("user", "What's the weather in Tokyo?")]})
print(result["messages"][-1].content)
```

### **CrewAI Multi-Agent**

```python
from crewai import Agent, Task, Crew, LLM

llm = LLM(model='gemini/gemini-2.5-flash')

researcher = Agent(
    role='Researcher',
    goal='Research the topic',
    llm=llm
)

writer = Agent(
    role='Writer',
    goal='Write article',
    llm=llm
)

task1 = Task(description='Research AI trends', agent=researcher)
task2 = Task(description='Write article about findings', agent=writer)

crew = Crew(agents=[researcher, writer], tasks=[task1, task2])
result = crew.kickoff()
print(result)
```

---

## 🌟 **Context7 Library IDs for Documentation**

### **Agent Frameworks**

- **LangChain Python**: `/websites/python_langchain`
- **LangChain JavaScript**: `/websites/langchain_oss_javascript_langchain`
- **LangGraph**: `/websites/langchain_oss_javascript_langgraph`
- **LangChain Google**: `/langchain-ai/langchain-google`
- **CrewAI**: `/crewaiinc/crewai`
- **CrewAI Tools**: `/crewaiinc/crewai-tools`
- **LlamaIndex Python**: `/run-llama/llama_index`
- **LlamaIndex TypeScript**: `/run-llama/llamaindexts`

### **Google SDKs**

- **Google GenAI Python**: `/googleapis/python-genai`
- **Google GenAI JavaScript**: `/googleapis/js-genai`
- **Google GenAI Go**: `/googleapis/go-genai`

---

## 📚 **Additional Resources**

### **GitHub Repositories**

- [Gemini Cookbook](https://github.com/google-gemini/cookbook)
- [Python GenAI SDK](https://github.com/googleapis/python-genai)
- [LangChain](https://github.com/langchain-ai/langchain)
- [LangGraph](https://github.com/langchain-ai/langgraph)
- [CrewAI](https://github.com/crewaiinc/crewai)
- [CrewAI Examples](https://github.com/crewaiinc/crewai-examples)
- [LlamaIndex](https://github.com/run-llama/llama_index)
- [Vercel AI SDK](https://github.com/vercel/ai)

### **Tutorials & Guides**

- [ReAct Paper (2023)](https://arxiv.org/abs/2210.03629)
- [LangGraph Quickstart](https://langchain-ai.github.io/langgraph/tutorials/introduction/)
- [CrewAI Quickstart](https://docs.crewai.com/quickstart)
- [LlamaIndex Quickstart](https://docs.llamaindex.ai/en/stable/getting_started/starter_example/)

### **Community**

- [Gemini Community Forum](https://discuss.ai.google.dev/c/gemini-api/)
- [LangChain Discord](https://discord.gg/langchain)
- [Stack Overflow - gemini-api](https://stackoverflow.com/questions/tagged/gemini-api)

---

## 💰 **Pricing**

Function calling is included in standard Gemini API pricing based on tokens:

- Input tokens: Function declarations count toward input
- Output tokens: Function call responses count toward output

Check [Pricing Page](https://ai.google.dev/gemini-api/docs/pricing) for current rates.

---

## ⚠️ **Notes & Limitations**

### **General Limitations**

- Only subset of OpenAPI schema supported for function declarations
- Python automatic function calling is SDK-specific feature
- MCP support is experimental (Python & JavaScript only)

### **Supported Parameter Types (Python)**

```python
AllowedType = (
    int | float | bool | str |
    list['AllowedType'] |
    pydantic.BaseModel
)
```

### **Not Supported**

- Dict types like `dict[str: int]` (avoid in function parameters)
- Resources and prompts in MCP (tools only)

---

## 📝 **License Information**

- **Documentation**: [Creative Commons Attribution 4.0 License](https://creativecommons.org/licenses/by/4.0/)
- **Code Samples**: [Apache 2.0 License](https://www.apache.org/licenses/LICENSE-2.0)

---

**Document compiled on:** November 9, 2025  
**Data sources:** Official Google Gemini API documentation, agent framework documentation, and Context7 library documentation

For the most up-to-date information, always refer to:

- [Official Gemini API Documentation](https://ai.google.dev/gemini-api/docs)
- [Function Calling Guide](https://ai.google.dev/gemini-api/docs/function-calling)
- [Agent Framework Documentation](#agent-frameworks-integration)
