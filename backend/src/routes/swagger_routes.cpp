#include "nexus/routes/swagger_routes.h"
#include <drogon/drogon.h>
#include "nexus/utils/openapi_generator.h"
#include "nexus/middleware/cors.h"

namespace nexus::routes {

namespace {

const char *kSwaggerHtml = R"HTML(<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Nexus CSF API Docs</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" />
  <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css" />
  <style>
    body {
      background: #f8f9fa;
      color: #212529;
    }
    .docs-navbar {
      background: #ffffff;
      border-bottom: 1px solid #dee2e6;
      box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
    }
    .docs-navbar .brand-dot {
      width: 10px;
      height: 10px;
      border-radius: 50%;
      background: #0dcaf0;
      display: inline-block;
    }
    .docs-hero {
      background: #ffffff;
      border: 1px solid #dee2e6;
      border-radius: 0.75rem;
      padding: 1.25rem 1.5rem;
      margin-bottom: 1rem;
    }
    .swagger-panel {
      background: #ffffff;
      border: 1px solid #dee2e6;
      border-radius: 0.75rem;
      padding: 0.5rem 1rem 1.5rem;
      box-shadow: 0 1px 4px rgba(0, 0, 0, 0.04);
    }
    .swagger-ui .topbar { display: none; }
    .swagger-ui .info .title { color: #212529; }
    .swagger-ui .info p,
    .swagger-ui .info li,
    .swagger-ui .info table { color: #495057; }
    .swagger-ui .opblock-tag {
      color: #212529;
      border-bottom: 1px solid #dee2e6;
    }
    .swagger-ui .opblock {
      border-radius: 0.5rem;
      margin-bottom: 0.75rem;
      box-shadow: 0 1px 2px rgba(0, 0, 0, 0.04);
    }
    .swagger-ui .btn.execute {
      background: #0d6efd;
      border-color: #0d6efd;
    }
    .swagger-ui .btn.execute:hover {
      background: #0b5ed7;
      border-color: #0a58ca;
    }
    .swagger-ui section.models {
      border: 1px solid #dee2e6;
      border-radius: 0.5rem;
      background: #ffffff;
    }
  </style>
</head>
<body>
  <nav class="navbar docs-navbar sticky-top">
    <div class="container-fluid px-4">
      <span class="navbar-brand mb-0 h1 fs-5 fw-semibold">
        <span class="brand-dot me-2"></span>Nexus CSF API
      </span>
      <div class="d-flex align-items-center gap-2">
        <span class="badge text-bg-success">Live</span>
        <a class="btn btn-sm btn-outline-primary" href="/api/openapi.yaml" target="_blank" rel="noopener">OpenAPI YAML</a>
        <a class="btn btn-sm btn-outline-secondary" href="/api/health" target="_blank" rel="noopener">Health</a>
      </div>
    </div>
  </nav>

  <main class="container-fluid px-4 py-3">
    <div class="docs-hero">
      <div class="row g-3 align-items-center">
        <div class="col-lg-8">
          <h2 class="h4 mb-2">Interactive API Documentation</h2>
          <p class="text-secondary mb-0">
            Browse all endpoints, inspect schemas, and try API calls directly from your browser.
            New routes are auto-added when not yet listed in the curated spec.
          </p>
        </div>
        <div class="col-lg-4">
          <div class="small text-secondary">Base URL</div>
          <code id="base-url" class="d-block mt-1"></code>
        </div>
      </div>
    </div>

    <div class="swagger-panel">
      <div id="swagger-ui"></div>
    </div>
  </main>

  <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
  <script>
    document.getElementById('base-url').textContent = window.location.origin;
    window.onload = function () {
      SwaggerUIBundle({
        url: '/api/openapi.yaml',
        dom_id: '#swagger-ui',
        deepLinking: true,
        docExpansion: 'list',
        defaultModelsExpandDepth: 1,
        displayRequestDuration: true,
        tryItOutEnabled: true,
        presets: [SwaggerUIBundle.presets.apis],
        layout: 'BaseLayout',
      });
    };
  </script>
  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
)HTML";

}  // namespace

void registerSwaggerRoutes() {
    using namespace drogon;

    app().registerHandler(
        "/api/openapi.yaml",
        [](const HttpRequestPtr &,
           std::function<void(const HttpResponsePtr &)> &&callback) {
            auto resp = HttpResponse::newHttpResponse();
            resp->setStatusCode(k200OK);
            resp->setContentTypeCode(CT_TEXT_PLAIN);
            resp->addHeader("Content-Type", "application/yaml; charset=utf-8");
            resp->setBody(nexus::utils::generateOpenApiYaml());
            middleware::addCors(resp);
            callback(resp);
        },
        {Get});

    app().registerHandler(
        "/api/docs",
        [](const HttpRequestPtr &,
           std::function<void(const HttpResponsePtr &)> &&callback) {
            auto resp = HttpResponse::newHttpResponse();
            resp->setStatusCode(k200OK);
            resp->setContentTypeCode(CT_TEXT_HTML);
            resp->setBody(kSwaggerHtml);
            middleware::addCors(resp);
            callback(resp);
        },
        {Get});
}

}  // namespace nexus::routes
