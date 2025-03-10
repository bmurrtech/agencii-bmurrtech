from agency_swarm.agents import Agent

from .tools.Agent2.ExampleTool2 import ExampleTool2
from .tools.ExampleTool3 import ExampleTool3


class Agent2(Agent):
    def __init__(self):
        super().__init__(
            name="Agent2",
            description="The Agent2 is the second agent in the agency.",
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