"""
AI Agent Tool Registry for Krushi Setu

Provides function tool declarations and execution handlers for AI tool-calling.
Exposes standard tools for:
- Weather forecast retrieval
- Knowledge Base search (RAG)
- Farmer profile retrieval
- General agronomic fertilizer dose calculator
"""

import logging
from typing import Dict, Any, List, Callable, Optional
from pydantic import BaseModel

logger = logging.getLogger(__name__)


class ToolParameter(BaseModel):
    type: str
    description: str
    required: bool = False


class ToolDefinition(BaseModel):
    name: str
    description: str
    parameters: Dict[str, Any]


class AgentToolRegistry:
    """
    Registry for AI agent function tools.
    """

    def __init__(self):
        self._tools: Dict[str, ToolDefinition] = {}
        self._handlers: Dict[str, Callable] = {}
        self._register_default_tools()

    def register_tool(
        self,
        name: str,
        description: str,
        parameters: Dict[str, Any],
        handler: Callable,
    ):
        """Register a new function tool with its execution handler."""
        tool = ToolDefinition(
            name=name,
            description=description,
            parameters=parameters,
        )
        self._tools[name] = tool
        self._handlers[name] = handler
        logger.info(f"Registered agent tool: {name}")

    def get_tool_definitions(self) -> List[Dict[str, Any]]:
        """Return tool definitions formatted for LLM function calling schemas."""
        return [
            {
                "type": "function",
                "function": {
                    "name": tool.name,
                    "description": tool.description,
                    "parameters": tool.parameters,
                },
            }
            for tool in self._tools.values()
        ]

    async def execute_tool(self, name: str, arguments: Dict[str, Any]) -> Dict[str, Any]:
        """Execute a tool by name with arguments."""
        if name not in self._handlers:
            raise ValueError(f"Unknown tool: {name}")

        handler = self._handlers[name]
        logger.info(f"Executing tool '{name}' with args: {arguments}")
        try:
            if callable(handler):
                import inspect
                if inspect.iscoroutinefunction(handler):
                    result = await handler(**arguments)
                else:
                    result = handler(**arguments)
                return {"status": "success", "result": result}
        except Exception as e:
            logger.error(f"Tool execution failed for '{name}': {e}")
            return {"status": "error", "error": str(e)}

    def _register_default_tools(self):
        """Register default Krushi Setu tools."""

        # 1. Weather Forecast Tool
        async def handle_weather(latitude: float, longitude: float):
            from app.services.weather.weather_service import WeatherService
            service = WeatherService()
            weather = await service.get_weather(latitude, longitude)
            return weather.model_dump() if weather else {"error": "Weather unavailable"}

        self.register_tool(
            name="get_weather_forecast",
            description="Fetch current weather and 7-day forecast for a farm location (lat, lon).",
            parameters={
                "type": "object",
                "properties": {
                    "latitude": {"type": "number", "description": "Farm latitude"},
                    "longitude": {"type": "number", "description": "Farm longitude"},
                },
                "required": ["latitude", "longitude"],
            },
            handler=handle_weather,
        )

        # 2. Knowledge Search Tool
        async def handle_kb_search(query: str, category: Optional[str] = None):
            from app.services.knowledge.retriever import KnowledgeRetriever
            retriever = KnowledgeRetriever()
            chunks = retriever.search(query=query, top_k=3, category=category)
            return [
                {
                    "title": c.document_title,
                    "heading": c.section_heading,
                    "content": c.content,
                    "score": c.score,
                }
                for c in chunks
            ]

        self.register_tool(
            name="search_knowledge_base",
            description="Search agricultural knowledge base (schemes, crop guides, pest guides).",
            parameters={
                "type": "object",
                "properties": {
                    "query": {"type": "string", "description": "Agricultural question or topic"},
                    "category": {
                        "type": "string",
                        "description": "Optional category filter: government_scheme, pest_disease, crop_guide",
                    },
                },
                "required": ["query"],
            },
            handler=handle_kb_search,
        )

        # 3. Fertilizer Calculation Tool
        def handle_fertilizer(crop: str, area_acres: float):
            # Standard generalized guidelines per acre
            crop_lower = crop.lower()
            if "ragi" in crop_lower:
                npk = "100:50:50 kg NPK per hectare (approx 40:20:20 kg/acre)"
                urea = round(area_acres * 45, 1)
                dap = round(area_acres * 40, 1)
                mop = round(area_acres * 30, 1)
            elif "tomato" in crop_lower:
                npk = "150:100:100 kg NPK per hectare (approx 60:40:40 kg/acre)"
                urea = round(area_acres * 65, 1)
                dap = round(area_acres * 80, 1)
                mop = round(area_acres * 60, 1)
            else:
                npk = "80:40:40 kg NPK per hectare general recommendation"
                urea = round(area_acres * 35, 1)
                dap = round(area_acres * 35, 1)
                mop = round(area_acres * 25, 1)

            return {
                "crop": crop,
                "area_acres": area_acres,
                "recommendation": npk,
                "suggested_bags_approx": {
                    "Urea_kg": urea,
                    "DAP_kg": dap,
                    "MOP_kg": mop,
                },
                "disclaimer": "Consult local KVK or soil testing lab for exact field-specific doses.",
            }

        self.register_tool(
            name="calculate_fertilizer_dosage",
            description="Calculate general fertilizer requirements (NPK, Urea, DAP, MOP) for a crop and land area.",
            parameters={
                "type": "object",
                "properties": {
                    "crop": {"type": "string", "description": "Crop name (e.g. Ragi, Tomato, Paddy)"},
                    "area_acres": {"type": "number", "description": "Farm land area in acres"},
                },
                "required": ["crop", "area_acres"],
            },
            handler=handle_fertilizer,
        )
