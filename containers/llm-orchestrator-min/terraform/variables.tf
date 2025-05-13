variable "aws_region" {
  description = "Region AWS, w którym zostanie wdrożona infrastruktura"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Środowisko (np. dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "model_service_count" {
  description = "Liczba instancji usługi modelu"
  type        = number
  default     = 1
}

variable "api_gateway_count" {
  description = "Liczba instancji API Gateway"
  type        = number
  default     = 2
}

variable "model_service_cpu" {
  description = "Przydzielone CPU dla usługi modelu (w jednostkach AWS)"
  type        = string
  default     = "2048"
}

variable "model_service_memory" {
  description = "Przydzielona pamięć dla usługi modelu (w MB)"
  type        = string
  default     = "4096"
}

variable "api_gateway_cpu" {
  description = "Przydzielone CPU dla API Gateway (w jednostkach AWS)"
  type        = string
  default     = "512"
}

variable "api_gateway_memory" {
  description = "Przydzielona pamięć dla API Gateway (w MB)"
  type        = string
  default     = "1024"
}

variable "model_path" {
  description = "Ścieżka do modelu wewnątrz kontenera"
  type        = string
  default     = "/app/models/tinyllama"
}

variable "use_int8" {
  description = "Czy używać kwantyzacji INT8 dla modelu"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tagi do zastosowania do wszystkich zasobów"
  type        = map(string)
  default = {
    Project     = "llm-orchestrator"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
