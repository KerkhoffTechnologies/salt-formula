{% set processed_gitdirs = [] %}
{% set processed_basedirs = [] %}

{% from "salt/formulas.jinja" import formulas_git_opt with context %}

# Loop over all formulas listed in pillar data
{% for env, entries in salt['pillar.get']('salt_formulas:list', {}).items() %}
{% for list_entry in entries %}

{% set entry_opts = [] %}
{% set entry = '' %}

{% if list_entry is not string %}
{% set entry = list_entry.items()[0][0] %}
{% set entry_opts = list_entry.items()[0][1] %}
{% else %}
{% set entry = list_entry %}
{% endif %}

{% set basedir = formulas_git_opt(env, 'basedir')|load_yaml %}
{% set gitdir = '{0}/{1}'.format(basedir, entry) %}

{% if 'update' in entry_opts %}
{% set update = entry_opts['update'] %}
{% else %}
{% set update = formulas_git_opt(env, 'update')|load_yaml %}
{% endif %}

# Setup the directory hosting the Git repository
{% if basedir not in processed_basedirs %}
{% do processed_basedirs.append(basedir) %}
{{ basedir }}:
  file.directory:
    {%- for key, value in salt['pillar.get']('salt_formulas:basedir_opts',
                                             {'makedirs': True}).items() %}
    - {{ key }}: {{ value }}
    {%- endfor %}
{% endif %}

# Setup the formula Git repository
{% if gitdir not in processed_gitdirs %}
{% do processed_gitdirs.append(gitdir) %}

{% if 'options' in entry_opts %}
{% set options = entry_opts['options'] %}
{% else %}
{% set options = formulas_git_opt(env, 'options')|load_yaml %}
{% endif %}

{% if 'baseurl' in entry_opts %}
{% set baseurl = entry_opts['baseurl'] %}
{% else %}
{% set baseurl = formulas_git_opt(env, 'baseurl')|load_yaml %}
{% endif %}

{{ gitdir }}:
  git.latest:
    - name: {{ baseurl }}/{{ entry }}.git
    - target: {{ gitdir }}
    {%- for key, value in options.items() %}
    - {{ key }}: {{ value }}
    {%- endfor %}
    - require:
      - file: {{ basedir }}
    {%- if not update %}
    - unless: test -e {{ gitdir }}
    {%- endif %}
{% endif %}

{% endfor %}
{% endfor %}
