<?php
declare(strict_types=1);

namespace DKTrack;

class Router
{
    private array $routes = [];

    public function add(string $method, string $path, callable|array $handler): void
    {
        $this->routes[] = [
            'method'  => strtoupper($method),
            'pattern' => $this->convertPathToRegex($path),
            'handler' => $handler
        ];
    }

    public function get(string $path, callable|array $handler): void
    {
        $this->add('GET', $path, $handler);
    }

    public function post(string $path, callable|array $handler): void
    {
        $this->add('POST', $path, $handler);
    }

    public function put(string $path, callable|array $handler): void
    {
        $this->add('PUT', $path, $handler);
    }

    public function delete(string $path, callable|array $handler): void
    {
        $this->add('DELETE', $path, $handler);
    }

    public function dispatch(): void
    {
        // 1. CORS Preflight & Global Headers
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
        header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Idempotency-Key');
        header('Content-Type: application/json; charset=utf-8');

        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
        if ($method === 'OPTIONS') {
            http_response_code(200);
            exit();
        }

        $uri = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH);

        // Strip prefix if hosted under a subdirectory (e.g., /api/v1)
        foreach ($this->routes as $route) {
            if ($route['method'] === $method && preg_match($route['pattern'], $uri, $matches)) {
                array_shift($matches); // Remove full match
                
                $input = json_decode(file_get_contents('php://input'), true) ?? $_POST;
                $params = array_merge($matches, [$_GET, $input]);

                try {
                    $handler = $route['handler'];
                    if (is_array($handler)) {
                        [$class, $action] = $handler;
                        $controller = new $class();
                        $response = $controller->$action(...$params);
                    } else {
                        $response = $handler(...$params);
                    }
                    echo json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
                } catch (\Throwable $e) {
                    http_response_code(500);
                    echo json_encode([
                        'success' => false,
                        'error'   => 'Internal Server Error',
                        'message' => $e->getMessage()
                    ], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
                }
                return;
            }
        }

        // Route not found
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'error'   => 'Not Found',
            'path'    => $uri,
            'message' => 'The requested endpoint does not exist.'
        ], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }

    private function convertPathToRegex(string $path): string
    {
        $escaped = preg_replace('/\{([a-zA-Z0-9_]+)\}/', '([a-zA-Z0-9_\-]+)', $path);
        return '#^' . $escaped . '$#';
    }
}
