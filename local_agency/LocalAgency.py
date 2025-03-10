import os
import sys
from dotenv import load_dotenv
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.append(project_root)
from agency_swarm import Agency  # noqa: E402

from local_agency import LocalAgent1, LocalAgent2  # noqa: E402

load_dotenv()

agent_1 = LocalAgent1()
agent_2 = LocalAgent2()

agency = Agency(
    [agent_1, agent_2],
    shared_instructions="./agency_manifesto.md",  # shared instructions for all agents
    max_prompt_tokens=25000,  # default tokens in conversation for all agents
    temperature=0.0,  # default temperature for all agents
)

if __name__ == "__main__":
    agency.demo_gradio()