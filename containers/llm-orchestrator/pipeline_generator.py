# containers/llm-orchestrator/pipeline_generator.py
import json
import os
from typing import Dict, List, Any


class PipelineGenerator:
    """Generator pipeline'ów dla popularnych portali pracy"""

    def __init__(self, llm_manager):
        self.llm_manager = llm_manager
        self.pipeline_templates_dir = "/app/pipeline_templates"
        self.user_pipelines_dir = "/volumes/config/pipelines"

        # Upewnij się, że katalogi istnieją
        os.makedirs(self.pipeline_templates_dir, exist_ok=True)
        os.makedirs(self.user_pipelines_dir, exist_ok=True)

        # Załaduj bazę wiedzy o portalach pracy
        self.job_portals_knowledge = self._load_job_portals_knowledge()

    def _load_job_portals_knowledge(self) -> Dict[str, Any]:
        """Ładuje bazę wiedzy o portalach pracy"""
        knowledge_path = "/app/data/job_portals_knowledge.json"
        try:
            with open(knowledge_path, 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            # Tworzenie podstawowego szablonu, jeśli plik nie istnieje
            basic_knowledge = {
                "portals": {
                    "linkedin.com": {
                        "login_selectors": {"username": "#username", "password": "#password",
                                            "submit": ".login__form_action_container button"},
                        "job_listing_selectors": {"container": ".jobs-search-results__list",
                                                  "items": ".jobs-search-results__list-item"},
                        "application_form_selectors": {"container": ".jobs-easy-apply-content", "fields": {
                            "name": "#text-entity-list-form-component-formElement-urn-li-jobs-applyformcommon-easyApplyFormElement-3-name-firstName",
                            "email": "#text-entity-list-form-component-formElement-urn-li-jobs-applyformcommon-easyApplyFormElement-3-name-emailAddress"}}
                    },
                    "pracuj.pl": {
                        "login_selectors": {"username": "#email", "password": "#password",
                                            "submit": "button[type='submit']"},
                        "job_listing_selectors": {"container": ".results__list", "items": ".results__list-item"},
                        "application_form_selectors": {"container": ".application-form",
                                                       "fields": {"name": "#name", "email": "#email",
                                                                  "cv_upload": "#cv"}}
                    },
                    "stepstone.de": {
                        "login_selectors": {"username": "#loginEmail", "password": "#loginPassword",
                                            "submit": "button[type='submit']"},
                        "job_listing_selectors": {"container": ".job-items", "items": ".job-item"},
                        "application_form_selectors": {"container": "#jobapplicationform",
                                                       "fields": {"first_name": "#firstname", "last_name": "#lastname",
                                                                  "email": "#email", "cv_upload": "#cv"}}
                    }
                }
            }

            # Zapisz domyślną wiedzę
            os.makedirs(os.path.dirname(knowledge_path), exist_ok=True)
            with open(knowledge_path, 'w') as f:
                json.dump(basic_knowledge, f, indent=2)

            return basic_knowledge

    def generate_pipeline(self, portal_url: str, cv_path: str) -> Dict[str, Any]:
        """Generuje pipeline dla danego portalu pracy"""
        # Wykryj portal na podstawie URL
        portal_name = self._detect_portal(portal_url)

        if not portal_name:
            # Użyj LLM do analizy nieznanego portalu
            return self._generate_custom_pipeline(portal_url, cv_path)

        # Pobierz szablon dla znanego portalu
        portal_knowledge = self.job_portals_knowledge["portals"].get(portal_name, {})

        # Wygeneruj pipeline
        pipeline = {
            "name": f"Pipeline dla {portal_name}",
            "url": portal_url,
            "cv_path": cv_path,
            "steps": [
                {
                    "type": "navigation",
                    "action": "goto",
                    "url": portal_url
                }
            ]
        }

        # Dodaj krok logowania, jeśli mamy selektory
        if "login_selectors" in portal_knowledge:
            pipeline["steps"].append({
                "type": "authentication",
                "selectors": portal_knowledge["login_selectors"],
                "use_password_manager": True
            })

        # Dodaj kroki wyszukiwania i wypełniania formularzy
        if "application_form_selectors" in portal_knowledge:
            pipeline["steps"].append({
                "type": "form_filling",
                "selectors": portal_knowledge["application_form_selectors"],
                "cv_data_mapping": {
                    "name": "personal_info.name",
                    "email": "personal_info.email",
                    "cv_upload": cv_path
                }
            })

        # Zapisz pipeline do pliku
        pipeline_path = os.path.join(self.user_pipelines_dir, f"{portal_name}_pipeline.json")
        with open(pipeline_path, 'w') as f:
            json.dump(pipeline, f, indent=2)

        return pipeline

    def _detect_portal(self, url: str) -> str:
        """Wykrywa portal pracy na podstawie URL"""
        for portal in self.job_portals_knowledge["portals"]:
            if portal in url:
                return portal
        return None

    def _generate_custom_pipeline(self, url: str, cv_path: str) -> Dict[str, Any]:
        """Generuje niestandardowy pipeline dla nieznanego portalu przy użyciu LLM"""
        # Użyj LLM do analizy strony i sugierowania pipeline
        prompt = f"""
        Analizuję stronę internetową {url}, która wydaje się być portalem pracy.
        Potrzebuję stworzyć pipeline do automatyzacji aplikowania o pracę.

        Proszę o sugestię kroków, które należy wykonać, aby:
        1. Znaleźć formularze aplikacyjne
        2. Wypełnić je danymi z CV
        3. Przesłać CV i inne wymagane dokumenty

        Sugeruj konkretne selektory CSS lub XPath, które mogą być używane do identyfikacji elementów formularza.
        """

        # Używamy LLM do analizy i generowania sugestii
        result = self.llm_manager.generate_text(prompt)

        # Spróbuj sparsować sugestie jako strukturę JSON
        try:
            # Próba ekstraktowania JSON z odpowiedzi
            import re
            json_match = re.search(r'```json\n(.*?)\n```', result, re.DOTALL)
            if json_match:
                pipeline_suggestion = json.loads(json_match.group(1))
            else:
                # Użyj LLM do strukturyzacji odpowiedzi w formacie JSON
                structuring_prompt = f"""
                Przekształć poniższą odpowiedź w strukturę JSON pipeline:

                {result}

                Format oczekiwanej odpowiedzi:
                {{
                  "name": "Pipeline dla nieznanego portalu",
                  "url": "{url}",
                  "steps": [
                    {{
                      "type": "navigation",
                      "action": "goto",
                      "url": "{url}"
                    }},
                    ...
                  ]
                }}
                """
                structured_result = self.llm_manager.generate_text(structuring_prompt)
                # Wyciągnij JSON z odpowiedzi
                json_match = re.search(r'```json\n(.*?)\n```', structured_result, re.DOTALL)
                if json_match:
                    pipeline_suggestion = json.loads(json_match.group(1))
                else:
                    json_start = structured_result.find('{')
                    json_end = structured_result.rfind('}') + 1
                    if json_start >= 0 and json_end > json_start:
                        pipeline_json = structured_result[json_start:json_end]
                        pipeline_suggestion = json.loads(pipeline_json)
                    else:
                        raise ValueError("Nie można znaleźć prawidłowej struktury JSON w odpowiedzi")

            # Dodaj ścieżkę do CV
            pipeline_suggestion["cv_path"] = cv_path

            # Zapisz wygenerowany pipeline
            portal_identifier = url.replace("https://", "").replace("http://", "").split("/")[0].replace(".", "_")
            pipeline_path = os.path.join(self.user_pipelines_dir, f"custom_{portal_identifier}_pipeline.json")
            with open(pipeline_path, 'w') as f:
                json.dump(pipeline_suggestion, f, indent=2)

            return pipeline_suggestion

        except Exception as e:
            # W przypadku błędu, zwróć podstawowy pipeline
            basic_pipeline = {
                "name": f"Podstawowy pipeline dla {url}",
                "url": url,
                "cv_path": cv_path,
                "steps": [
                    {
                        "type": "navigation",
                        "action": "goto",
                        "url": url
                    },
                    {
                        "type": "analysis",
                        "action": "detect_forms",
                        "note": f"Nie udało się wygenerować niestandardowego pipeline: {str(e)}"
                    }
                ]
            }

            # Zapisz podstawowy pipeline
            portal_identifier = url.replace("https://", "").replace("http://", "").split("/")[0].replace(".", "_")
            pipeline_path = os.path.join(self.user_pipelines_dir, f"basic_{portal_identifier}_pipeline.json")
            with open(pipeline_path, 'w') as f:
                json.dump(basic_pipeline, f, indent=2)

            return basic_pipeline