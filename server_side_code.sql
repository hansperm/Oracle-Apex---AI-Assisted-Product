DECLARE
    l_request        CLOB;
    l_response       CLOB;
    l_gpt_category   VARCHAR2(4000);
    l_category_list  VARCHAR2(4000);
BEGIN

---------------------------------------------------
-- 1. Build category list
---------------------------------------------------
SELECT LISTAGG(CATEGORY_NAME, ', ')
       WITHIN GROUP (ORDER BY CATEGORY_NAME)
INTO l_category_list
FROM PRODUCT_CATEGORY;

---------------------------------------------------
-- 2. Build Cohere request JSON (SAFE FORMAT)
---------------------------------------------------
apex_json.initialize_clob_output;
apex_json.open_object;

apex_json.write('model', 'command-a-03-2025');

apex_json.write('message',
    'Return ONLY one category name from the list. ' ||
    'If no match return UNKNOWN. ' ||
    'Product: ' || :P2_PRODUCT_NAME || '. ' ||
    'Categories: ' || l_category_list
);

apex_json.write('temperature', 0);

apex_json.close_object;

l_request := apex_json.get_clob_output;
apex_json.free_output;

---------------------------------------------------
-- 3. SET HEADERS MANUALLY (WORKAROUND)
---------------------------------------------------
apex_web_service.g_request_headers.delete;

apex_web_service.g_request_headers(1).name  := 'Content-Type';
apex_web_service.g_request_headers(1).value := 'application/json';

apex_web_service.g_request_headers(2).name  := 'Authorization';
apex_web_service.g_request_headers(2).value := 'Bearer zjY7I8rubuW069ZhT5OaLId0pmqKcVY9TD0KH1wT';

---------------------------------------------------
-- 4. CALL COHERE API
---------------------------------------------------
BEGIN
    l_response := apex_web_service.make_rest_request(
        p_url         => 'https://api.cohere.ai/v1/chat',
        p_http_method => 'POST',
        p_body        => l_request
    );

    IF l_response IS NULL THEN
        :P2_GPT_RAW := 'API ERROR: EMPTY RESPONSE (CHECK API KEY / NETWORK)';
        :P2_CATEGORY_ID := NULL;
        RETURN;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        :P2_GPT_RAW := 'API ERROR: ' || SQLERRM;
        :P2_CATEGORY_ID := NULL;
        RETURN;
END;

---------------------------------------------------
-- 5. Save raw response
---------------------------------------------------
:P2_GPT_RAW := DBMS_LOB.SUBSTR(l_response, 4000);

---------------------------------------------------
-- 6. Parse response (Cohere chat format)
---------------------------------------------------
BEGIN
    apex_json.parse(l_response);

    l_gpt_category := TRIM(
        apex_json.get_varchar2('text')
    );

EXCEPTION
    WHEN OTHERS THEN
        :P2_GPT_RAW := 'PARSE ERROR: ' || SQLERRM || ' | ' || :P2_GPT_RAW;
        :P2_CATEGORY_ID := NULL;
        RETURN;
END;

---------------------------------------------------
-- 7. Normalize
---------------------------------------------------
l_gpt_category := UPPER(TRIM(l_gpt_category));

---------------------------------------------------
-- 8. Handle UNKNOWN
---------------------------------------------------
IF l_gpt_category IS NULL OR l_gpt_category = 'UNKNOWN' THEN
    :P2_CATEGORY_ID := NULL;
    :P2_GPT_RAW := :P2_GPT_RAW || ' | NO MATCH';
    RETURN;
END IF;

---------------------------------------------------
-- 9. SAFE MATCH (NO ORA ERRORS)
---------------------------------------------------
SELECT MIN(CATEGORY_ID)
INTO :P2_CATEGORY_ID
FROM PRODUCT_CATEGORY
WHERE UPPER(CATEGORY_NAME) = l_gpt_category
   OR UPPER(CATEGORY_NAME) LIKE '%' || l_gpt_category || '%'
   OR l_gpt_category LIKE '%' || UPPER(CATEGORY_NAME) || '%';

---------------------------------------------------
-- 10. Log if not found
---------------------------------------------------
IF :P2_CATEGORY_ID IS NULL THEN
    :P2_GPT_RAW := :P2_GPT_RAW || ' | NO MATCH FOUND: ' || l_gpt_category;
END IF;

EXCEPTION
    WHEN OTHERS THEN
        :P2_CATEGORY_ID := NULL;
        :P2_GPT_RAW := 'FINAL ERROR: ' || SQLERRM;
END;DECLARE
    l_request        CLOB;
    l_response       CLOB;
    l_gpt_category   VARCHAR2(4000);
    l_category_list  VARCHAR2(4000);
BEGIN

---------------------------------------------------
-- 1. Build category list
---------------------------------------------------
SELECT LISTAGG(CATEGORY_NAME, ', ')
       WITHIN GROUP (ORDER BY CATEGORY_NAME)
INTO l_category_list
FROM PRODUCT_CATEGORY;

---------------------------------------------------
-- 2. Build Cohere request JSON (SAFE FORMAT)
---------------------------------------------------
apex_json.initialize_clob_output;
apex_json.open_object;

apex_json.write('model', 'command-a-03-2025');

apex_json.write('message',
    'Return ONLY one category name from the list. ' ||
    'If no match return UNKNOWN. ' ||
    'Product: ' || :P2_PRODUCT_NAME || '. ' ||
    'Categories: ' || l_category_list
);

apex_json.write('temperature', 0);

apex_json.close_object;

l_request := apex_json.get_clob_output;
apex_json.free_output;

---------------------------------------------------
-- 3. SET HEADERS MANUALLY (WORKAROUND)
---------------------------------------------------
apex_web_service.g_request_headers.delete;

apex_web_service.g_request_headers(1).name  := 'Content-Type';
apex_web_service.g_request_headers(1).value := 'application/json';

apex_web_service.g_request_headers(2).name  := 'Authorization';
apex_web_service.g_request_headers(2).value := 'Bearer zjY7I8rubuW069ZhT5OaLId0pmqKcVY9TD0KH1wT';

---------------------------------------------------
-- 4. CALL COHERE API
---------------------------------------------------
BEGIN
    l_response := apex_web_service.make_rest_request(
        p_url         => 'https://api.cohere.ai/v1/chat',
        p_http_method => 'POST',
        p_body        => l_request
    );

    IF l_response IS NULL THEN
        :P2_GPT_RAW := 'API ERROR: EMPTY RESPONSE (CHECK API KEY / NETWORK)';
        :P2_CATEGORY_ID := NULL;
        RETURN;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        :P2_GPT_RAW := 'API ERROR: ' || SQLERRM;
        :P2_CATEGORY_ID := NULL;
        RETURN;
END;

---------------------------------------------------
-- 5. Save raw response
---------------------------------------------------
:P2_GPT_RAW := DBMS_LOB.SUBSTR(l_response, 4000);

---------------------------------------------------
-- 6. Parse response (Cohere chat format)
---------------------------------------------------
BEGIN
    apex_json.parse(l_response);

    l_gpt_category := TRIM(
        apex_json.get_varchar2('text')
    );

EXCEPTION
    WHEN OTHERS THEN
        :P2_GPT_RAW := 'PARSE ERROR: ' || SQLERRM || ' | ' || :P2_GPT_RAW;
        :P2_CATEGORY_ID := NULL;
        RETURN;
END;

---------------------------------------------------
-- 7. Normalize
---------------------------------------------------
l_gpt_category := UPPER(TRIM(l_gpt_category));

---------------------------------------------------
-- 8. Handle UNKNOWN
---------------------------------------------------
IF l_gpt_category IS NULL OR l_gpt_category = 'UNKNOWN' THEN
    :P2_CATEGORY_ID := NULL;
    :P2_GPT_RAW := :P2_GPT_RAW || ' | NO MATCH';
    RETURN;
END IF;

---------------------------------------------------
-- 9. SAFE MATCH (NO ORA ERRORS)
---------------------------------------------------
SELECT MIN(CATEGORY_ID)
INTO :P2_CATEGORY_ID
FROM PRODUCT_CATEGORY
WHERE UPPER(CATEGORY_NAME) = l_gpt_category
   OR UPPER(CATEGORY_NAME) LIKE '%' || l_gpt_category || '%'
   OR l_gpt_category LIKE '%' || UPPER(CATEGORY_NAME) || '%';

---------------------------------------------------
-- 10. Log if not found
---------------------------------------------------
IF :P2_CATEGORY_ID IS NULL THEN
    :P2_GPT_RAW := :P2_GPT_RAW || ' | NO MATCH FOUND: ' || l_gpt_category;
END IF;

EXCEPTION
    WHEN OTHERS THEN
        :P2_CATEGORY_ID := NULL;
        :P2_GPT_RAW := 'FINAL ERROR: ' || SQLERRM;
END;
