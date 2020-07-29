{# Set configuration variables #}
{%- set project_name = 'myproject' -%}
{%- set project_debug = True -%}
{%- set environment_name = 'dev' -%} {# Use 'dev' or 'prod' #}
{%- set db_name = project_name ~ '_' ~ environment_name -%}
{%- set db_root_user = 'root' -%}
{%- set db_root_pass = 'REPLACE_PASSWORD' -%}
{%- set db_user = db_name ~ '_user' -%}
{%- set db_atomic = True -%}
{%- set django_secret_key = 'REPLACE_WITH_A_SECURE_KEY' -%}
{%- set project_host = 'localhost' -%}
{%- set project_port = '8000' -%}
{%- set email_default_from = 'no-reply@' ~ project_host -%}
{%- set email_host = 'localhost' -%}
{%- set email_port = 25 -%}
{%- set email_host_user = 'vagrant' -%}
{%- set email_host_pass = 'password' -%}
{%- set email_server = 'no-reply@' ~ project_host -%}
{%- set email_subject_prefix = project_name -%}
{%- set email_use_ssl = False -%}
{%- set email_use_tls = False -%}
{%- set log_path = '/var/log' -%}
{%- set python = '/usr/bin/python3' -%}
{%- set django_admin_name = 'Admin' -%}
{%- set django_admin_email = 'admin134353@email258385.com' -%}
{%- set django_time_zone = 'America/New_York' -%}

{%- if environment_name == 'dev' %}
  {%- set db_user = project_name ~ '_user' -%}
  {%- set db_pass = 'password' -%}
  {%- set db_host = 'localhost' -%}
  {%- set db_port = '336' -%}
  {%- set project_debug = True -%}
  {%- set project_path = '/home/vagrant' -%}
  {%- set project_user = 'vagrant' -%}
{%- else %}
  {# set default configuration variables for prod in future #}
{%- endif %}

project:
  environment:
    database:
      root_user: {{ db_root_user }}
      root_pass: {{ db_root_pass }}
    debug: {{ project_debug }}
    host: {{ project_host }}
    port: {{ project_port }}
    log: {{ log_path }}
    name: {{ environment_name }}
    path: {{ project_path }}
    python: {{ python }}
    user: {{ project_user }}
  django:
    path: {{ project_path }}/project
    settings:
      {%- if environment_name != 'dev' %}
      allowed_hosts:
      {%- for host in allowed_hosts %}
        - {{ host }}
      {%- endfor %}
      {%- endif %}
      admins:
        - name: {{ django_admin_name }}
          email: {{ django_admin_email }}
      debug: {{ project_debug }}
      database:
        engine: django.db.backends.mysql
        name: {{ db_name }}
        user: {{ db_user }}
        pass: {{ db_pass }}
        host: {{ db_host }}
        port: {{ db_port }}
        atomic: {{ db_atomic }}
      email:
        backend: django.core.mail.backends.smtp.EmailBackend
        default_from: {{ email_default_from }}
        host: {{ email_host }}
        host_user: {{ email_host_user }}
        host_password: {{ email_host_pass }}
        port: {{ email_port }}
        server: {{ email_server }}
        subject_prefix: {{ email_subject_prefix }}
        use_ssl: {{ email_use_ssl }}
        use_tls: {{ email_use_tls }}
      media: /media
      secret_key: '{{ django_secret_key }}'
      static: /static
      time_zone: {{ django_time_zone }}
  gunicorn:
    bind: 0.0.0.0:8000
    log:
      error: {{ log_path }}/gunicorn.err.log
      out: {{ log_path }}/gunicorn.out.log
    wsgi: project.wsgi
  name: {{ project_name }}
  packages:
    - python3-dev
    - python3-pip
    - python3-venv
    - mariadb-server
    - mariadb-client
    - libmariadbclient-dev
    - supervisor
    - apache2
  supervisor:
    username: {{ project_user }}
    password: password
  virtualenv:
    name: venv
    path: /home/vagrant
    user: {{ project_user }}
