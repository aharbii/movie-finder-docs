# AI Pipeline Requirements

## State and Isolation

The pipeline shall carry all data between processing stages through a single shared state object. No stage shall communicate with another stage through any mechanism other than this shared state.

Each processing stage shall be a self-contained, stateless function. A stage shall produce a partial state update as its output and shall have no persistent side effects between invocations.

## Search and Ranking

The pipeline shall encode the user's natural language description as a high-dimensional vector and perform similarity search over a pre-indexed movie corpus. Results shall be ranked by semantic similarity.

Candidate results below a configurable confidence threshold shall be excluded from the response presented to the user.

## Metadata Enrichment

The pipeline shall enrich each candidate with live external metadata before presenting results to the user. Enrichment failure for a single candidate shall not block or discard the remaining candidates.

External metadata requests shall be made in a manner that respects rate limits of the upstream data provider.

## Routing and Phase Management

The pipeline shall classify the conversation phase based on the current state and user input, and route control to the appropriate processing stage without requiring manual phase tracking by the caller.

The pipeline shall enforce a maximum number of refinement cycles. When the maximum is reached without a confirmed match, the pipeline shall produce a graceful end-of-search response rather than repeating the cycle.

## Q&A Agent

The Q&A stage shall use a reasoning agent capable of using tools to look up information dynamically. The agent shall operate within the scope of the confirmed movie and shall have access to external metadata retrieval as a tool.

## Model Selection

The pipeline shall use different language models for different stages based on task complexity. Lightweight classification tasks shall use a smaller, faster model. Complex reasoning and Q&A tasks shall use a more capable model. The model for each stage shall be configurable without code changes.

## Observability

The pipeline shall support opt-in execution tracing. When enabled, all stage invocations, inputs, and outputs shall be recorded in an external tracing system. Tracing shall have no effect on pipeline behaviour when disabled.

## Configuration

All pipeline parameters — model identifiers, similarity thresholds, maximum cycles, search depth — shall be externalised as configuration values. No tuning parameter shall be hardcoded in the pipeline logic.
