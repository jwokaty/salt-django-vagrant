#! jinja|yaml

{% set project = salt['pillar.get']('project') %}

project_pkgs_installed:
  pkg.installed:
    - pkgs:
      {% for pkg in project.packages -%}
      - {{ pkg }}
      {% endfor %}

project_virtualenv_created:
  cmd.run:
    - name: {{ project.environment.python }} -m venv {{ project.environment.path }}/{{ project.virtualenv.name }}
    - user: {{ project.virtualenv.user }}
    - require:
      - pkg: project_pkgs_installed

project_pip_installed:
  pip.installed:
    - requirements: salt://project/files/pip/requirements.txt
    - user: {{ project.virtualenv.user }}
    - bin_env: {{ project.virtualenv.path }}/{{ project.virtualenv.name }}
    - require:
      - cmd: project_virtualenv_created

project_database_configured:
  file.managed:
    - name: /etc/mysql/conf.d/mysql.cnf
    - source: salt://project/files/mysql/mysql.cnf.jinja
    - user: {{ project.environment.database.root_user }}
    - group: {{ project.environment.database.root_user }}
    - mode: 644
    - template: jinja
    - require:
      - pip: project_pip_installed

project_database_created:
  cmd.run:
    - name: mysql -e "CREATE DATABASE IF NOT EXISTS {{ project.django.settings.database.name }};"
    - require:
      - file: project_database_configured

project_database_user_created:
  cmd.run:
    - name: mysql -e "CREATE USER IF NOT EXISTS '{{ project.django.settings.database.user }}'@'{{ project.django.settings.database.host }}' IDENTIFIED BY '{{ project.django.settings.database.pass }}';"
    - require:
      - cmd: project_database_created

project_database_user_permissions_granted:
  cmd.run:
    - name: mysql -e "GRANT ALL ON {{ project.django.settings.database.name }}.* TO '{{ project.django.settings.database.user }}'@'{{ project.django.settings.database.host }}' IDENTIFIED BY '{{ project.django.settings.database.pass }}'; FLUSH PRIVILEGES;"
    - require:
      - cmd: project_database_user_created

{%- if project.environment.name == 'dev' %}
project_test_database_user_permissions_granted:
  cmd.run:
    - name: mysql -e "GRANT ALL ON test_{{ project.django.settings.database.name }}.* TO '{{ project.django.settings.database.user }}'@'{{ project.django.settings.database.host }}' IDENTIFIED BY '{{ project.django.settings.database.pass }}'; FLUSH PRIVILEGES;"
    - require:
      - cmd: project_database_user_permissions_granted
{%- endif %}

project_django_settings_created:
  file.managed:
    - name: {{ project.django.path }}/project/settings.py
    - source: salt://project/files/django/settings.py.jinja
    - user: {{ project.environment.user }}
    - group: {{ project.environment.user }}
    - mode: 644
    - template: jinja
    - require:
      - cmd: project_database_user_permissions_granted

project_django_log_created:
  file.managed:
    - name: {{ project.environment.log }}/{{ project.name }}.log
    - user: {{ project.environment.user }}
    - group: {{ project.environment.user }}
    - mode: 644
    - replace: False
    - require:
      - file: project_django_settings_created

supervisor_directory_created:
  file.directory:
    - name: /etc/supervisor/conf.d
    - dir_mode: 755
    - file_mode: 644
    - makedirs: True
    - recurse:
      - user
      - group
      - mode
    - require:
      - file: project_django_log_created

gunicorn_error_log_created:
  file.managed:
    - name: {{ project.environment.log }}/gunicorn.err.log
    - mode: 644
    - replace: False
    - require:
      - file: supervisor_directory_created

gunicorn_log_created:
  file.managed:
    - name: {{ project.environment.log }}/gunicorn.out.log
    - mode: 644
    - replace: False
    - require:
      - file: gunicorn_error_log_created

gunicorn_conf_created:
  file.managed:
    - name: /etc/supervisor/conf.d/gunicorn.conf
    - source: salt://project/files/gunicorn/gunicorn.conf.jinja
    - mode: 644
    - template: jinja
    - require:
      - file: gunicorn_log_created

supervisor_conf_created:
  file.managed:
    - name: /etc/supervisor/supervisord.conf
    - source: salt://project/files/supervisor/supervisord.conf.jinja
    - mode: 644
    - template: jinja
    - require:
      - file: gunicorn_conf_created

project_supervisor_restarted:
  cmd.run:
    - name: service supervisor restart
    - require:
      - file: supervisor_conf_created

project_apache_conf_created:
  file.managed:
    - name: /etc/apache2/sites-available/project.conf
    - source: salt://project/files/apache2/project.conf.jinja
    - user: {{ project.environment.user }}
    - group: {{ project.environment.user }}
    - mode: 644
    - template: jinja
    - require:
      - cmd: project_supervisor_restarted

project_apache_symlink_created:
  file.symlink:
    - name: /etc/apache2/sites-enabled/project.conf
    - target: /etc/apache2/sites-available/project.conf
    - mode: 644
    - template: jinja
    - require:
      - file: project_apache_conf_created

project_apache_default_disabled:
  apache_site.disabled:
    - name: 000-default
    - require:
      - file: project_apache_symlink_created

project_apache_project_enabled:
  apache_site.enabled:
    - name: project
    - require:
      - apache_site: project_apache_default_disabled

project_apache_proxy_enabled:
  apache_module.enabled:
    - name: proxy
    - require:
      - apache_site: project_apache_project_enabled

project_apache_proxy_http_enabled:
  apache_module.enabled:
    - name: proxy_http
    - require:
      - apache_module: project_apache_proxy_enabled

project_apache_restarted:
  service.running:
    - name: apache2
    - enable: True
    - reload: True
    - watch:
      - apache_module: project_apache_proxy_http_enabled
