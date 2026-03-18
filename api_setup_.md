If you are using PowerShell on Windows, you will need to escape the double quotes for the command to work:

docker exec denchclaw node denchclaw.mjs --profile dench config set models.providers.dashscope '{\"apiKey\": \"sk-b5ad...\", \"baseUrl\": \"https://dashscope.aliyuncs.com/compatible-mode/v1\", \"api\": \"openai-completions\", \"models\": [{\"id\": \"qwen3.5-flash\", \"name\": \"Qwen 3.5 Flash\", \"contextWindow\": 128000, \"maxTokens\": 4096}]}'

docker exec denchclaw node denchclaw.mjs --profile dench config set agents.defaults.model "dashscope/qwen3.5-flash"
