{% macro convert_timezone(column_name, from_tz='UTC', to_tz='America/Chicago') %}
    ({{ column_name }} AT TIME ZONE '{{ from_tz }}' AT TIME ZONE '{{ to_tz }}')
{% endmacro %}

{% macro to_local_time(column_name) %}
    {{ convert_timezone(column_name, 'UTC', 'America/Chicago') }}
{% endmacro %}
