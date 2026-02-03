# Ideogram MCP Server - API Reference

Complete API reference for all tools provided by the Ideogram MCP Server.

## Table of Contents

- [Overview](#overview)
- [Tools](#tools)
  - [ideogram_generate](#ideogram_generate)
  - [ideogram_generate_async](#ideogram_generate_async)
  - [ideogram_edit](#ideogram_edit)
  - [ideogram_get_prediction](#ideogram_get_prediction)
  - [ideogram_cancel_prediction](#ideogram_cancel_prediction)
- [Common Types](#common-types)
  - [Aspect Ratios](#aspect-ratios)
  - [Rendering Speed](#rendering-speed)
  - [Magic Prompt](#magic-prompt)
  - [Style Types](#style-types)
  - [Cost Estimates](#cost-estimates)
- [Error Handling](#error-handling)
- [Environment Variables](#environment-variables)

---

## Overview

The Ideogram MCP Server provides 5 tools for AI image generation and editing:

| Tool | Purpose | Synchronous |
|------|---------|-------------|
| `ideogram_generate` | Generate images from text prompts | Yes |
| `ideogram_generate_async` | Queue image generation for background processing | No |
| `ideogram_edit` | Edit images using inpainting or outpainting | Yes |
| `ideogram_get_prediction` | Check status of async generation requests | Yes |
| `ideogram_cancel_prediction` | Cancel queued async requests | Yes |

**Note:** The Ideogram API is synchronous only. The "async" tools (`ideogram_generate_async`, `ideogram_get_prediction`, `ideogram_cancel_prediction`) provide a local job queue implementation for background processing.

---

## Tools

### ideogram_generate

Generate images from text prompts using Ideogram AI v3.

#### Description

Creates high-quality AI-generated images based on text descriptions. Supports various aspect ratios, rendering quality levels, and style options. Returns image URLs, seeds for reproducibility, and cost estimates.

#### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `prompt` | string | **Yes** | - | Text description of the desired image (1-10,000 characters) |
| `negative_prompt` | string | No | - | Text describing what to avoid in the image (max 10,000 characters) |
| `aspect_ratio` | string | No | `"1x1"` | Image aspect ratio (see [Aspect Ratios](#aspect-ratios)) |
| `num_images` | integer | No | `1` | Number of images to generate (1-8) |
| `seed` | integer | No | - | Random seed for reproducible generation (0-2,147,483,647) |
| `rendering_speed` | string | No | `"DEFAULT"` | Quality/speed tradeoff (see [Rendering Speed](#rendering-speed)) |
| `magic_prompt` | string | No | `"AUTO"` | Prompt enhancement option (see [Magic Prompt](#magic-prompt)) |
| `style_type` | string | No | `"AUTO"` | Visual style for the image (see [Style Types](#style-types)) |
| `save_locally` | boolean | No | `true` | Whether to save images to local storage |

#### Response

```typescript
// Success Response
{
  success: true,
  created: "2024-01-15T10:30:00Z",  // Timestamp
  images: [
    {
      url: "https://ideogram.ai/...",     // Temporary URL (expires)
      local_path: "./ideogram_images/...", // Local path if save_locally=true
      seed: 12345,                         // Seed used for this image
      is_image_safe: true,                 // Safety filter result
      prompt: "Enhanced prompt...",        // Final prompt (if magic_prompt applied)
      resolution: "1024x1024"              // Image dimensions
    }
  ],
  total_cost: {
    credits_used: 1,
    estimated_usd: 0.04,
    pricing_tier: "DEFAULT",
    num_images: 1
  },
  num_images: 1
}

// Error Response
{
  success: false,
  error_code: "RATE_LIMITED",
  error: "Rate limit exceeded",
  user_message: "Too many requests. Please wait a moment and try again.",
  retryable: true
}
```

#### Examples

**Basic generation:**
```json
{
  "prompt": "A serene Japanese garden with cherry blossoms and a koi pond"
}
```

**High-quality panoramic:**
```json
{
  "prompt": "Dramatic sunset over mountain peaks with golden clouds",
  "aspect_ratio": "16x9",
  "rendering_speed": "QUALITY",
  "style_type": "REALISTIC"
}
```

**Multiple variations:**
```json
{
  "prompt": "Minimalist logo design for a coffee shop",
  "num_images": 4,
  "style_type": "DESIGN"
}
```

**Reproducible generation:**
```json
{
  "prompt": "A futuristic cityscape at night",
  "seed": 42,
  "aspect_ratio": "16x9"
}
```

---

### ideogram_generate_async

Queue an image generation request for background processing.

#### Description

Returns immediately with a `prediction_id` that can be used to poll for status and results using `ideogram_get_prediction`. This is a **local async implementation** since the Ideogram API is synchronous only.

Use this when you want to:
- Queue multiple generations without waiting
- Continue working while images generate in the background
- Have more control over the generation workflow

#### Parameters

All parameters from `ideogram_generate` plus:

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `webhook_url` | string (URL) | No | - | Reserved for future notification support |

#### Response

```typescript
{
  success: true,
  prediction_id: "pred_abc123...",  // Unique ID for polling
  status: "queued",                  // Always "queued" on success
  eta_seconds: 30,                   // Estimated time to completion
  message: "Image generation queued successfully..."
}
```

#### Example

```json
{
  "prompt": "An astronaut exploring an alien planet",
  "num_images": 4,
  "rendering_speed": "QUALITY"
}
```

**Response:**
```json
{
  "success": true,
  "prediction_id": "pred_7f8e9d0c",
  "status": "queued",
  "eta_seconds": 45,
  "message": "Image generation queued successfully. Use ideogram_get_prediction with prediction_id \"pred_7f8e9d0c\" to check status and retrieve results."
}
```

---

### ideogram_edit

Edit existing images using inpainting or outpainting.

#### Description

- **Inpainting:** Edit specific parts of an image using a mask. The mask defines which areas to modify (black = edit, white = preserve).
- **Outpainting:** Expand an image in one or more directions by generating new content that matches the original.

#### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `prompt` | string | **Yes** | - | Text describing the desired changes (1-10,000 characters) |
| `image` | string | **Yes** | - | Source image: URL, file path, or base64 data URL |
| `mask` | string | No | - | Mask image for inpainting (black=edit, white=preserve) |
| `mode` | string | No | `"inpaint"` | Edit mode: `"inpaint"` or `"outpaint"` |
| `expand_directions` | array | No | - | For outpainting: directions to expand (`["left", "right", "up", "down"]`) |
| `expand_pixels` | integer | No | - | For outpainting: pixels to expand (1-1024) |
| `negative_prompt` | string | No | - | Text describing what to avoid |
| `num_images` | integer | No | `1` | Number of images to generate (1-8) |
| `seed` | integer | No | - | Random seed (0-2,147,483,647) |
| `rendering_speed` | string | No | `"DEFAULT"` | Quality/speed tradeoff |
| `magic_prompt` | string | No | `"AUTO"` | Prompt enhancement option |
| `style_type` | string | No | `"AUTO"` | Visual style |
| `save_locally` | boolean | No | `true` | Save images locally |

#### Response

Same structure as `ideogram_generate` plus:

```typescript
{
  success: true,
  created: "2024-01-15T10:30:00Z",
  images: [...],
  total_cost: {...},
  num_images: 1,
  mode: "inpaint"  // or "outpaint"
}
```

#### Examples

**Inpainting - Replace sky:**
```json
{
  "prompt": "Replace with a dramatic sunset sky with orange and purple clouds",
  "image": "https://example.com/photo.jpg",
  "mask": "data:image/png;base64,...",
  "mode": "inpaint"
}
```

**Outpainting - Expand landscape:**
```json
{
  "prompt": "Continue the mountain landscape with more peaks and forest",
  "image": "https://example.com/landscape.jpg",
  "mode": "outpaint",
  "expand_directions": ["left", "right"],
  "expand_pixels": 200
}
```

**Inpainting - Add object:**
```json
{
  "prompt": "Add a hot air balloon floating in the sky",
  "image": "/path/to/local/image.jpg",
  "mask": "/path/to/mask.png",
  "mode": "inpaint",
  "num_images": 3
}
```

---

### ideogram_get_prediction

Check the status of an async image generation request.

#### Description

Polls the local job queue to check the status of a prediction created with `ideogram_generate_async`. Use this to monitor progress and retrieve completed results.

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `prediction_id` | string | **Yes** | The unique ID returned from `ideogram_generate_async` |

#### Response

**Processing (queued or in-progress):**
```typescript
{
  success: true,
  prediction_id: "pred_abc123",
  status: "queued" | "processing",
  eta_seconds: 25,      // Estimated time remaining
  progress: 40,         // Percentage complete (0-100)
  message: "Prediction is processing. Please poll again in a few seconds."
}
```

**Completed:**
```typescript
{
  success: true,
  prediction_id: "pred_abc123",
  status: "completed",
  created: "2024-01-15T10:30:00Z",
  images: [
    {
      url: "https://ideogram.ai/...",
      seed: 12345,
      is_image_safe: true,
      prompt: "Enhanced prompt...",
      resolution: "1024x1024"
    }
  ],
  total_cost: {
    credits_used: 1,
    estimated_usd: 0.04,
    pricing_tier: "DEFAULT",
    num_images: 1
  },
  num_images: 1
}
```

**Failed or Cancelled:**
```typescript
{
  success: false,
  prediction_id: "pred_abc123",
  status: "failed" | "cancelled",
  error: {
    code: "API_ERROR",
    message: "Ideogram API returned an error",
    retryable: true
  },
  message: "Prediction failed: Ideogram API returned an error. This error may be retryable."
}
```

#### Example Workflow

```typescript
// 1. Queue an async generation
const queueResult = await ideogram_generate_async({
  prompt: "A magical forest"
});
const predictionId = queueResult.prediction_id;

// 2. Poll until complete
let result;
do {
  result = await ideogram_get_prediction({
    prediction_id: predictionId
  });

  if (result.status === "queued" || result.status === "processing") {
    await sleep(5000); // Wait 5 seconds before polling again
  }
} while (result.status === "queued" || result.status === "processing");

// 3. Handle result
if (result.status === "completed") {
  console.log("Images:", result.images);
} else {
  console.error("Failed:", result.error);
}
```

---

### ideogram_cancel_prediction

Cancel a queued async image generation request.

#### Description

Cancels a prediction that was created with `ideogram_generate_async`. **Only works for predictions in `queued` status.** Once a prediction starts processing (submitted to the Ideogram API), it cannot be cancelled.

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `prediction_id` | string | **Yes** | The unique ID to cancel |

#### Response

**Successfully Cancelled:**
```typescript
{
  success: true,
  prediction_id: "pred_abc123",
  status: "cancelled",
  message: "Prediction successfully cancelled. No credits will be used."
}
```

**Cannot Cancel:**
```typescript
{
  success: false,
  prediction_id: "pred_abc123",
  status: "processing" | "completed" | "failed",
  reason: "Cannot cancel - prediction is already being processed",
  message: "Cannot cancel this prediction because it is already being processed by the Ideogram API."
}
```

#### Example

```json
{
  "prediction_id": "pred_7f8e9d0c"
}
```

---

## Common Types

### Aspect Ratios

All 15 supported aspect ratios for image generation:

| Ratio | Use Case |
|-------|----------|
| `1x1` | Square images, profile pictures, social media posts |
| `16x9` | Widescreen, YouTube thumbnails, presentations |
| `9x16` | Vertical video, Instagram/TikTok stories |
| `4x3` | Traditional photo format |
| `3x4` | Portrait orientation |
| `3x2` | DSLR photo aspect |
| `2x3` | Portrait DSLR |
| `4x5` | Instagram portrait post |
| `5x4` | Landscape photo |
| `1x2` | Tall vertical |
| `2x1` | Wide horizontal |
| `1x3` | Very tall vertical |
| `3x1` | Very wide horizontal |
| `10x16` | Tall portrait |
| `16x10` | Wide landscape |

**Note:** Use "x" separator (e.g., `"16x9"`), not ":" (e.g., ~~`"16:9"`~~).

### Rendering Speed

Controls the quality/speed tradeoff:

| Value | Speed | Quality | Credits | Best For |
|-------|-------|---------|---------|----------|
| `FLASH` | Fastest | Lower | Lowest | Quick iterations, drafts |
| `TURBO` | Fast | Good | Low | Balanced speed/quality |
| `DEFAULT` | Balanced | High | Medium | General use |
| `QUALITY` | Slowest | Highest | Highest | Final renders, professional work |

### Magic Prompt

Automatic prompt enhancement options:

| Value | Behavior |
|-------|----------|
| `AUTO` | Let Ideogram decide based on prompt complexity |
| `ON` | Always enhance the prompt for better results |
| `OFF` | Use the prompt exactly as provided |

Magic prompt enhancement adds details and artistic direction to improve generation quality.

### Style Types

Visual style presets:

| Value | Description |
|-------|-------------|
| `AUTO` | Let Ideogram choose the best style |
| `GENERAL` | Versatile, balanced style |
| `REALISTIC` | Photorealistic, lifelike images |
| `DESIGN` | Clean, graphic design aesthetic |
| `FICTION` | Artistic, imaginative style |

### Cost Estimates

All generation responses include cost information:

```typescript
{
  credits_used: number,     // Estimated credits consumed
  estimated_usd: number,    // Estimated cost in USD
  pricing_tier: string,     // Rendering speed used
  num_images: number        // Number of images in request
}
```

**Note:** Cost estimates are calculated locally based on known Ideogram pricing. The Ideogram API does not return actual cost data.

---

## Error Handling

All tools return structured error responses when something goes wrong:

```typescript
{
  success: false,
  error_code: string,      // Programmatic error identifier
  error: string,           // Technical error message
  user_message: string,    // User-friendly explanation
  retryable: boolean,      // Whether the operation can be retried
  details?: object         // Additional error information
}
```

### Common Error Codes

| Code | Description | Retryable |
|------|-------------|-----------|
| `INVALID_API_KEY` | API key is missing or invalid | No |
| `RATE_LIMITED` | Too many requests | Yes |
| `INSUFFICIENT_CREDITS` | Not enough credits | No |
| `VALIDATION_ERROR` | Invalid input parameters | No |
| `NETWORK_ERROR` | Connection issues | Yes |
| `TIMEOUT` | Request timed out | Yes |
| `API_ERROR` | Ideogram API error | Maybe |
| `NOT_FOUND` | Prediction not found | No |
| `INTERNAL_ERROR` | Server error | Yes |

### Error Handling Example

```typescript
const result = await ideogram_generate({
  prompt: "A beautiful sunset"
});

if (!result.success) {
  console.error(`Error: ${result.user_message}`);

  if (result.retryable) {
    // Implement retry logic
    await sleep(5000);
    return retry();
  } else {
    // Handle non-retryable error
    throw new Error(result.error);
  }
}
```

---

## Environment Variables

Configure the server using these environment variables:

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `IDEOGRAM_API_KEY` | **Yes** | - | Your Ideogram API key |
| `LOG_LEVEL` | No | `info` | Logging level: `debug`, `info`, `warn`, `error` |
| `LOCAL_SAVE_DIR` | No | `./ideogram_images` | Directory for saved images |
| `ENABLE_LOCAL_SAVE` | No | `true` | Enable automatic local saving |
| `MAX_CONCURRENT_REQUESTS` | No | `3` | Rate limiting |
| `REQUEST_TIMEOUT_MS` | No | `30000` | API timeout (ms) |

### Claude Desktop Configuration

```json
{
  "mcpServers": {
    "ideogram": {
      "command": "node",
      "args": ["/path/to/ideogram-mcp-server/dist/index.js"],
      "env": {
        "IDEOGRAM_API_KEY": "your_api_key_here",
        "LOG_LEVEL": "info",
        "LOCAL_SAVE_DIR": "./my_images",
        "ENABLE_LOCAL_SAVE": "true"
      }
    }
  }
}
```

---

## See Also

- [Quickstart Guide](./QUICKSTART.md) - Get started in 5 minutes
- [README](../README.md) - Project overview and installation
- [Ideogram API Documentation](https://developer.ideogram.ai/) - Official Ideogram API docs
