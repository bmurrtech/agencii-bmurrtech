from agency_swarm.agents import Agent

from .tools import ExampleTool1
from .tools import ExampleTool3


class Agent1(Agent):
    def __init__(self):
        super().__init__(
            name="Agent1",
            description="The Agent1 is the first agent in the agency.",
            instructions="./instructions.md",
            files_folder="./files",
            schemas_folder="./schemas",
            tools=[
                TestTool,
            ],
            tools_folder="./tools",
            temperature=0.0,
            max_prompt_tokens=25000,
            model="gpt-4o-mini",  # adjust model as needed
        )