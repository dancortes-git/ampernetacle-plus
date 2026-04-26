---
agent: instructions-generator
name: generate-instructions
description: Use this prompt to generate a new agent instructions file for the project. Ensure that the instructions align with the project's purpose and coding conventions as outlined in AGENTS.md.
---

Take the information below and generate an agent instructions .md file for it in the /docs directory. If a .md filename is provided, use that, otherwise generate an appropriate filename based on the generated content. Make sure the instructions are concise and not too long. Make sure to update the AGENTS.md file to reference this new docs file. If no information is provided below, prompt the user to give the necessary details about the layer of architecture or coding standards to document.