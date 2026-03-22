workspace "Movie Finder" "Movie Recommendation System based on AI and RAG" {

    model {
        user = person "User" "A user who wants to find a movie based on a plot description."
        
        movieFinderSystem = softwareSystem "Movie Finder System" "Allows users to search for movies via an AI Agent using plot descriptions." {
            frontend = container "Web Application" "Provides the chat interface, movie cards, and feedback mechanisms." "Angular, Tailwind" "Web Browser"
            backendApi = container "Backend API" "Handles business logic, agent orchestration, and integrations." "FastAPI, Python"
            database = container "Relational Database" "Stores users, chat history, and feedback." "PostgreSQL" "Database"
            vectorStore = container "Vector Database" "Stores Wikipedia movie plot embeddings." "Qdrant" "Database"
            ragPipeline = container "RAG Ingestion Job" "Processes CSV dataset and ingests embeddings." "Python script" "Job"
        }

        openai = softwareSystem "AI Platform" "LLM provider for Agent logic and generation." "External System"
        imdbApi = softwareSystem "IMDBApi" "External API to fetch movie posters and rich metadata." "External System"

        # Relationships
        user -> frontend "Uses"
        frontend -> backendApi "Makes API calls to" "JSON/HTTPS"
        backendApi -> database "Reads from and writes to" "SQL/TCP"
        backendApi -> vectorStore "Queries embeddings from" "gRPC/HTTP"
        backendApi -> openai "Sends prompts and gets completions" "HTTPS"
        backendApi -> imdbApi "Fetches movie data" "HTTPS"
        
        ragPipeline -> vectorStore "Updates index" "gRPC/HTTP"
    }

    views {
        systemContext movieFinderSystem "SystemContext" {
            include *
            autoLayout lr
        }

        container movieFinderSystem "Containers" {
            include *
            autoLayout tb
        }

        theme default
        
        styles {
            element "Database" {
                shape Cylinder
            }
            element "Web Browser" {
                shape WebBrowser
            }
            element "External System" {
                background #999999
                color #ffffff
            }
        }
    }
}
