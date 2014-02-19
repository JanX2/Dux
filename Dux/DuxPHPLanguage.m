//
//  DuxPHPLanguage.m
//  Dux
//
//  Created by Abhi Beckert on 2011-11-16.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import "DuxPHPLanguage.h"

static NSRegularExpression *keywordsExpression;
static NSIndexSet *keywordIndexSet = nil;
static NSRange keywordIndexRange = {NSNotFound, 0};
static __weak id keywordIndexString = nil;

@implementation DuxPHPLanguage

+ (void)load
{
  [DuxLanguage registerLanguage:[self class]];
}

- (DuxLanguageElement *)baseElement
{
  return [DuxPHPBaseElement sharedInstance];
}

- (void)wrapCommentsAroundRange:(NSRange)commentRange ofTextView:(NSTextView *)textView
{
  NSString *existingString = [textView.textStorage.string substringWithRange:commentRange];
  
  NSString *commentedString= [NSString stringWithFormat:@"// %@", existingString];
  commentedString = [commentedString stringByReplacingOccurrencesOfString:@"(\n)" withString:@"$1// " options:NSRegularExpressionSearch range:NSMakeRange(0, commentedString.length)];
  
  [textView insertText:commentedString replacementRange:commentRange];
  [textView setSelectedRange:NSMakeRange(commentRange.location, commentedString.length)];
}

- (void)removeCommentsAroundRange:(NSRange)commentRange ofTextView:(NSTextView *)textView
{
  NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:@"^\\s*// ?" options:NSRegularExpressionAnchorsMatchLines error:NULL];
  
  NSMutableString *newString = [[textView.textStorage.string substringWithRange:commentRange] mutableCopy];
  [expression replaceMatchesInString:newString options:0 range:NSMakeRange(0, newString.length) withTemplate:@""];
  
  [textView insertText:[newString copy] replacementRange:commentRange];
  [textView setSelectedRange:NSMakeRange(commentRange.location, newString.length)];
}

+ (NSIndexSet *)keywordIndexSet
{
  return keywordIndexSet;
}

+ (NSRange)keywordIndexRange
{
  return keywordIndexRange;
}

+ (id)keywordIndexString
{
  return keywordIndexString;
}

- (void)prepareToParseTextStorage:(NSTextStorage *)textStorage inRange:(NSRange)range
{
  [super prepareToParseTextStorage:textStorage inRange:range];
  
  [self findKeywordsInString:textStorage.string inRange:range];
}

- (void)findKeywordsInString:(NSString *)string inRange:(NSRange)range
{
  if (!keywordsExpression) {
    NSArray *keywords = [[NSArray alloc] initWithObjects:@"abstract", @"and", @"array", @"as", @"break", @"case", @"catch", @"cfunction", @"class", @"clone", @"const", @"continue", @"declare", @"default", @"die", @"do", @"double", @"else", @"elseif", @"empty", @"enddeclare", @"endfor", @"endforeach", @"endif", @"endswitch", @"endwhile", @"eval", @"exit", @"extends", @"false", @"final", @"float", @"for", @"foreach", @"function", @"global", @"goto", @"if", @"implements", @"include", @"instanceof", @"int", @"integer", @"interface", @"isset", @"namespace", @"new", @"null", @"old_function", @"or", @"print"@"private", @"protected", @"public", @"return", @"require", @"require_once", @"string", @"static", @"switch", @"throw", @"true", @"try", @"use", @"var", @"while", @"xor", @"__CLASS__", @"__DIR__", @"__FILE__", @"__FUNCTION__", @"__LINE__", @"__METHOD__", @"__NAMESPACE__", nil];
    
    keywordsExpression = [[NSRegularExpression alloc] initWithPattern:[[NSString alloc] initWithFormat:@"\\b(%@)\\b", [keywords componentsJoinedByString:@"|"]] options:NSRegularExpressionCaseInsensitive error:NULL];
  }
  
  NSMutableIndexSet *keywordIndexesMutable = [[NSIndexSet indexSet] mutableCopy];
  [keywordsExpression enumerateMatchesInString:string options:0 range:range usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
    [keywordIndexesMutable addIndexesInRange:match.range];
  }];
  
  keywordIndexSet = [keywordIndexesMutable copy];
  keywordIndexRange = range;
  keywordIndexString = string;
}

+ (BOOL)isDefaultLanguageForURL:(NSURL *)URL textContents:(NSString *)textContents
{
  if (URL && [[URL pathExtension] isEqualToString:@"php"])
    return YES;
  
  if (textContents.length >= 5 && [[textContents substringToIndex:5] isEqualToString:@"<?php"])
    return YES;
  
  return NO;
}

- (void)findSymbolsInDocumentContents:(NSString *)string foundSymbolHandler:(BOOL(^) (NSDictionary *symbol))foundSymbolHandler finishedSearchHandler:(void(^)())finishedHandler
{
  NSArray *keywords = [[NSArray alloc] initWithObjects:@"class", @"function", @"interface", nil];
  NSRegularExpression *keywordRegex = [[NSRegularExpression alloc] initWithPattern:[[NSString alloc] initWithFormat:@"\\b((%@\\s+([a-z0-9_]+)))\\b", [keywords componentsJoinedByString:@"\\s+([a-z0-9_]+))|("]] options:NSRegularExpressionCaseInsensitive error:NULL];
  
  string = string.copy;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    __block BOOL finishedHandlerCalled = NO;
    
    [keywordRegex enumerateMatchesInString:string options:0 range:NSMakeRange(0, string.length) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
      NSUInteger m = match.numberOfRanges;
      for (NSUInteger i = 2; i < m; i++) {
        BOOL isNameMatch = ((i - 1) % 2) == 0;
        if (!isNameMatch)
          continue;
        
        NSRange range = [match rangeAtIndex:i];
        if (range.location == NSNotFound)
          continue;
        
        NSString *name = [string substringWithRange:range];
        
        __block BOOL continueSearching;
        dispatch_sync(dispatch_get_main_queue(), ^{
          continueSearching = foundSymbolHandler(@{@"range": [NSValue valueWithRange:range], @"name": name});
        });
        if (!continueSearching) {
          finishedHandler();
          finishedHandlerCalled = YES;
          *stop = YES;
        }
      }
    }];
    
    if (!finishedHandlerCalled)
      finishedHandler();
  });
}

- (NSSet *)autocompleteWords
{
  static NSSet *set = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    
    NSMutableSet *mutableSet = [NSMutableSet set];
    
    // keywords
    [mutableSet addObjectsFromArray:@[@"__halt_compiler", @"abstract", @"and", @"array", @"as", @"break", @"callable", @"case", @"catch", @"class", @"clone", @"const", @"continue", @"declare", @"default", @"die", @"do", @"echo", @"else", @"elseif", @"empty", @"enddeclare", @"endfor", @"endforeach", @"endif", @"endswitch", @"endwhile", @"eval", @"exit", @"extends", @"final", @"for", @"foreach", @"function", @"global", @"goto", @"if", @"implements", @"include", @"include_once", @"instanceof", @"insteadof", @"interface", @"isset", @"list", @"namespace", @"new", @"or", @"print", @"private", @"protected", @"public", @"require", @"require_once", @"return", @"static", @"switch", @"throw", @"trait", @"try", @"unset", @"use", @"var", @"while", @"xor"]];
    
    // constants
    [mutableSet addObjectsFromArray:@[@"__CLASS__", @"__DIR__", @"__FILE__", @"__FUNCTION__", @"__LINE__", @"__METHOD__", @"__NAMESPACE__", @"__TRAIT__"]];
    
    // functions
    [mutableSet addObjectsFromArray:@[@"zend_version", @"func_num_args", @"func_get_arg", @"func_get_args", @"strlen", @"strcmp", @"strncmp", @"strcasecmp", @"strncasecmp", @"each", @"error_reporting", @"define", @"defined", @"get_class", @"get_called_class", @"get_parent_class", @"method_exists", @"property_exists", @"class_exists", @"interface_exists", @"function_exists", @"class_alias", @"get_included_files", @"get_required_files", @"is_subclass_of", @"is_a", @"get_class_vars", @"get_object_vars", @"get_class_methods", @"trigger_error", @"user_error", @"set_error_handler", @"restore_error_handler", @"set_exception_handler", @"restore_exception_handler", @"get_declared_classes", @"get_declared_interfaces", @"get_defined_functions", @"get_defined_vars", @"create_function", @"get_resource_type", @"get_loaded_extensions", @"extension_loaded", @"get_extension_funcs", @"get_defined_constants", @"debug_backtrace", @"debug_print_backtrace", @"gc_collect_cycles", @"gc_enabled", @"gc_enable", @"gc_disable", @"strtotime", @"date", @"idate", @"gmdate", @"mktime", @"gmmktime", @"checkdate", @"strftime", @"gmstrftime", @"time", @"localtime", @"getdate", @"date_create", @"date_create_from_format", @"date_parse", @"date_parse_from_format", @"date_get_last_errors", @"date_format", @"date_modify", @"date_add", @"date_sub", @"date_timezone_get", @"date_timezone_set", @"date_offset_get", @"date_diff", @"date_time_set", @"date_date_set", @"date_isodate_set", @"date_timestamp_set", @"date_timestamp_get", @"timezone_open", @"timezone_name_get", @"timezone_name_from_abbr", @"timezone_offset_get", @"timezone_transitions_get", @"timezone_location_get", @"timezone_identifiers_list", @"timezone_abbreviations_list", @"timezone_version_get", @"date_interval_create_from_date_string", @"date_interval_format", @"date_default_timezone_set", @"date_default_timezone_get", @"date_sunrise", @"date_sunset", @"date_sun_info", @"ereg", @"ereg_replace", @"eregi", @"eregi_replace", @"split", @"spliti", @"sql_regcase", @"libxml_set_streams_context", @"libxml_use_internal_errors", @"libxml_get_last_error", @"libxml_clear_errors", @"libxml_get_errors", @"libxml_disable_entity_loader", @"openssl_pkey_free", @"openssl_pkey_new", @"openssl_pkey_export", @"openssl_pkey_export_to_file", @"openssl_pkey_get_private", @"openssl_pkey_get_public", @"openssl_pkey_get_details", @"openssl_free_key", @"openssl_get_privatekey", @"openssl_get_publickey", @"openssl_x509_read", @"openssl_x509_free", @"openssl_x509_parse", @"openssl_x509_checkpurpose", @"openssl_x509_check_private_key", @"openssl_x509_export", @"openssl_x509_export_to_file", @"openssl_pkcs12_export", @"openssl_pkcs12_export_to_file", @"openssl_pkcs12_read", @"openssl_csr_new", @"openssl_csr_export", @"openssl_csr_export_to_file", @"openssl_csr_sign", @"openssl_csr_get_subject", @"openssl_csr_get_public_key", @"openssl_digest", @"openssl_encrypt", @"openssl_decrypt", @"openssl_cipher_iv_length", @"openssl_sign", @"openssl_verify", @"openssl_seal", @"openssl_open", @"openssl_pkcs7_verify", @"openssl_pkcs7_decrypt", @"openssl_pkcs7_sign", @"openssl_pkcs7_encrypt", @"openssl_private_encrypt", @"openssl_private_decrypt", @"openssl_public_encrypt", @"openssl_public_decrypt", @"openssl_get_md_methods", @"openssl_get_cipher_methods", @"openssl_dh_compute_key", @"openssl_random_pseudo_bytes", @"openssl_error_string", @"preg_match", @"preg_match_all", @"preg_replace", @"preg_replace_callback", @"preg_filter", @"preg_split", @"preg_quote", @"preg_grep", @"preg_last_error", @"readgzfile", @"gzrewind", @"gzclose", @"gzeof", @"gzgetc", @"gzgets", @"gzgetss", @"gzread", @"gzopen", @"gzpassthru", @"gzseek", @"gztell", @"gzwrite", @"gzputs", @"gzfile", @"gzcompress", @"gzuncompress", @"gzdeflate", @"gzinflate", @"gzencode", @"ob_gzhandler", @"zlib_get_coding_type", @"bzopen", @"bzread", @"bzwrite", @"bzflush", @"bzclose", @"bzerrno", @"bzerrstr", @"bzerror", @"bzcompress", @"bzdecompress", @"jdtogregorian", @"gregoriantojd", @"jdtojulian", @"juliantojd", @"jdtojewish", @"jewishtojd", @"jdtofrench", @"frenchtojd", @"jddayofweek", @"jdmonthname", @"easter_date", @"easter_days", @"unixtojd", @"jdtounix", @"cal_to_jd", @"cal_from_jd", @"cal_days_in_month", @"cal_info", @"ctype_alnum", @"ctype_alpha", @"ctype_cntrl", @"ctype_digit", @"ctype_lower", @"ctype_graph", @"ctype_print", @"ctype_punct", @"ctype_space", @"ctype_upper", @"ctype_xdigit", @"exif_read_data", @"read_exif_data", @"exif_tagname", @"exif_thumbnail", @"exif_imagetype", @"filter_input", @"filter_var", @"filter_input_array", @"filter_var_array", @"filter_list", @"filter_has_var", @"filter_id", @"ftp_connect", @"ftp_ssl_connect", @"ftp_login", @"ftp_pwd", @"ftp_cdup", @"ftp_chdir", @"ftp_exec", @"ftp_raw", @"ftp_mkdir", @"ftp_rmdir", @"ftp_chmod", @"ftp_alloc", @"ftp_nlist", @"ftp_rawlist", @"ftp_systype", @"ftp_pasv", @"ftp_get", @"ftp_fget", @"ftp_put", @"ftp_fput", @"ftp_size", @"ftp_mdtm", @"ftp_rename", @"ftp_delete", @"ftp_site", @"ftp_close", @"ftp_set_option", @"ftp_get_option", @"ftp_nb_fget", @"ftp_nb_get", @"ftp_nb_continue", @"ftp_nb_put", @"ftp_nb_fput", @"ftp_quit", @"textdomain", @"gettext", @"dgettext", @"dcgettext", @"bindtextdomain", @"ngettext", @"dngettext", @"dcngettext", @"bind_textdomain_codeset", @"gmp_init", @"gmp_intval", @"gmp_strval", @"gmp_add", @"gmp_sub", @"gmp_mul", @"gmp_div_qr", @"gmp_div_q", @"gmp_div_r", @"gmp_div", @"gmp_mod", @"gmp_divexact", @"gmp_neg", @"gmp_abs", @"gmp_fact", @"gmp_sqrt", @"gmp_sqrtrem", @"gmp_pow", @"gmp_powm", @"gmp_perfect_square", @"gmp_prob_prime", @"gmp_gcd", @"gmp_gcdext", @"gmp_invert", @"gmp_jacobi", @"gmp_legendre", @"gmp_cmp", @"gmp_sign", @"gmp_random", @"gmp_and", @"gmp_or", @"gmp_com", @"gmp_xor", @"gmp_setbit", @"gmp_clrbit", @"gmp_scan0", @"gmp_scan1", @"gmp_testbit", @"gmp_popcount", @"gmp_hamdist", @"gmp_nextprime", @"hash", @"hash_file", @"hash_hmac", @"hash_hmac_file", @"hash_init", @"hash_update", @"hash_update_stream", @"hash_update_file", @"hash_final", @"hash_copy", @"hash_algos", @"iconv", @"ob_iconv_handler", @"iconv_get_encoding", @"iconv_set_encoding", @"iconv_strlen", @"iconv_substr", @"iconv_strpos", @"iconv_strrpos", @"iconv_mime_encode", @"iconv_mime_decode", @"iconv_mime_decode_headers", @"session_name", @"session_module_name", @"session_save_path", @"session_id", @"session_regenerate_id", @"session_decode", @"session_register", @"session_unregister", @"session_is_registered", @"session_encode", @"session_start", @"session_destroy", @"session_unset", @"session_set_save_handler", @"session_cache_limiter", @"session_cache_expire", @"session_set_cookie_params", @"session_get_cookie_params", @"session_write_close", @"session_commit", @"shmop_open", @"shmop_read", @"shmop_close", @"shmop_size", @"shmop_write", @"shmop_delete", @"spl_classes", @"spl_autoload", @"spl_autoload_extensions", @"spl_autoload_register", @"spl_autoload_unregister", @"spl_autoload_functions", @"spl_autoload_call", @"class_parents", @"class_implements", @"spl_object_hash", @"iterator_to_array", @"iterator_count", @"iterator_apply", @"simplexml_load_file", @"simplexml_load_string", @"simplexml_import_dom", @"socket_select", @"socket_create", @"socket_create_listen", @"socket_create_pair", @"socket_accept", @"socket_set_nonblock", @"socket_set_block", @"socket_listen", @"socket_close", @"socket_write", @"socket_read", @"socket_getsockname", @"socket_getpeername", @"socket_connect", @"socket_strerror", @"socket_bind", @"socket_recv", @"socket_send", @"socket_recvfrom", @"socket_sendto", @"socket_get_option", @"socket_set_option", @"socket_shutdown", @"socket_last_error", @"socket_clear_error", @"socket_getopt", @"socket_setopt", @"constant", @"bin2hex", @"sleep", @"usleep", @"time_nanosleep", @"time_sleep_until", @"strptime", @"flush", @"wordwrap", @"htmlspecialchars", @"htmlentities", @"html_entity_decode", @"htmlspecialchars_decode", @"get_html_translation_table", @"sha1", @"sha1_file", @"md5", @"md5_file", @"crc32", @"iptcparse", @"iptcembed", @"getimagesize", @"image_type_to_mime_type", @"image_type_to_extension", @"phpinfo", @"phpversion", @"phpcredits", @"php_logo_guid", @"php_real_logo_guid", @"zend_logo_guid", @"php_sapi_name", @"php_uname", @"php_ini_scanned_files", @"php_ini_loaded_file", @"strnatcmp", @"strnatcasecmp", @"substr_count", @"strspn", @"strcspn", @"strtok", @"strtoupper", @"strtolower", @"strpos", @"stripos", @"strrpos", @"strripos", @"strrev", @"hebrev", @"hebrevc", @"nl2br", @"basename", @"dirname", @"pathinfo", @"stripslashes", @"stripcslashes", @"strstr", @"stristr", @"strrchr", @"str_shuffle", @"str_word_count", @"str_split", @"strpbrk", @"substr_compare", @"strcoll", @"money_format", @"substr", @"substr_replace", @"quotemeta", @"ucfirst", @"lcfirst", @"ucwords", @"strtr", @"addslashes", @"addcslashes", @"rtrim", @"str_replace", @"str_ireplace", @"str_repeat", @"count_chars", @"chunk_split", @"trim", @"ltrim", @"strip_tags", @"similar_text", @"explode", @"implode", @"join", @"setlocale", @"localeconv", @"nl_langinfo", @"soundex", @"levenshtein", @"chr", @"ord", @"parse_str", @"str_getcsv", @"str_pad", @"chop", @"strchr", @"sprintf", @"printf", @"vprintf", @"vsprintf", @"fprintf", @"vfprintf", @"sscanf", @"fscanf", @"parse_url", @"urlencode", @"urldecode", @"rawurlencode", @"rawurldecode", @"http_build_query", @"readlink", @"linkinfo", @"symlink", @"link", @"unlink", @"exec", @"system", @"escapeshellcmd", @"escapeshellarg", @"passthru", @"shell_exec", @"proc_open", @"proc_close", @"proc_terminate", @"proc_get_status", @"proc_nice", @"rand", @"srand", @"getrandmax", @"mt_rand", @"mt_srand", @"mt_getrandmax", @"getservbyname", @"getservbyport", @"getprotobyname", @"getprotobynumber", @"getmyuid", @"getmygid", @"getmypid", @"getmyinode", @"getlastmod", @"base64_decode", @"base64_encode", @"convert_uuencode", @"convert_uudecode", @"abs", @"ceil", @"floor", @"round", @"sin", @"cos", @"tan", @"asin", @"acos", @"atan", @"atanh", @"atan2", @"sinh", @"cosh", @"tanh", @"asinh", @"acosh", @"expm1", @"log1p", @"pi", @"is_finite", @"is_nan", @"is_infinite", @"pow", @"exp", @"log", @"log10", @"sqrt", @"hypot", @"deg2rad", @"rad2deg", @"bindec", @"hexdec", @"octdec", @"decbin", @"decoct", @"dechex", @"base_convert", @"number_format", @"fmod", @"inet_ntop", @"inet_pton", @"ip2long", @"long2ip", @"getenv", @"putenv", @"getopt", @"sys_getloadavg", @"microtime", @"gettimeofday", @"getrusage", @"uniqid", @"quoted_printable_decode", @"quoted_printable_encode", @"convert_cyr_string", @"get_current_user", @"set_time_limit", @"get_cfg_var", @"magic_quotes_runtime", @"set_magic_quotes_runtime", @"get_magic_quotes_gpc", @"get_magic_quotes_runtime", @"import_request_variables", @"error_log", @"error_get_last", @"call_user_func", @"call_user_func_array", @"call_user_method", @"call_user_method_array", @"forward_static_call", @"forward_static_call_array", @"serialize", @"unserialize", @"var_dump", @"var_export", @"debug_zval_dump", @"print_r", @"memory_get_usage", @"memory_get_peak_usage", @"register_shutdown_function", @"register_tick_function", @"unregister_tick_function", @"highlight_file", @"show_source", @"highlight_string", @"php_strip_whitespace", @"ini_get", @"ini_get_all", @"ini_set", @"ini_alter", @"ini_restore", @"get_include_path", @"set_include_path", @"restore_include_path", @"setcookie", @"setrawcookie", @"header", @"header_remove", @"headers_sent", @"headers_list", @"connection_aborted", @"connection_status", @"ignore_user_abort", @"parse_ini_file", @"parse_ini_string", @"is_uploaded_file", @"move_uploaded_file", @"gethostbyaddr", @"gethostbyname", @"gethostbynamel", @"gethostname", @"dns_check_record", @"checkdnsrr", @"dns_get_mx", @"getmxrr", @"dns_get_record", @"intval", @"floatval", @"doubleval", @"strval", @"gettype", @"settype", @"is_null", @"is_resource", @"is_bool", @"is_long", @"is_float", @"is_int", @"is_integer", @"is_double", @"is_real", @"is_numeric", @"is_string", @"is_array", @"is_object", @"is_scalar", @"is_callable", @"pclose", @"popen", @"readfile", @"rewind", @"rmdir", @"umask", @"fclose", @"feof", @"fgetc", @"fgets", @"fgetss", @"fread", @"fopen", @"fpassthru", @"ftruncate", @"fstat", @"fseek", @"ftell", @"fflush", @"fwrite", @"fputs", @"mkdir", @"rename", @"copy", @"tempnam", @"tmpfile", @"file", @"file_get_contents", @"file_put_contents", @"stream_select", @"stream_context_create", @"stream_context_set_params", @"stream_context_get_params", @"stream_context_set_option", @"stream_context_get_options", @"stream_context_get_default", @"stream_context_set_default", @"stream_filter_prepend", @"stream_filter_append", @"stream_filter_remove", @"stream_socket_client", @"stream_socket_server", @"stream_socket_accept", @"stream_socket_get_name", @"stream_socket_recvfrom", @"stream_socket_sendto", @"stream_socket_enable_crypto", @"stream_socket_shutdown", @"stream_socket_pair", @"stream_copy_to_stream", @"stream_get_contents", @"stream_supports_lock", @"fgetcsv", @"fputcsv", @"flock", @"get_meta_tags", @"stream_set_read_buffer", @"stream_set_write_buffer", @"set_file_buffer", @"set_socket_blocking", @"stream_set_blocking", @"socket_set_blocking", @"stream_get_meta_data", @"stream_get_line", @"stream_wrapper_register", @"stream_register_wrapper", @"stream_wrapper_unregister", @"stream_wrapper_restore", @"stream_get_wrappers", @"stream_get_transports", @"stream_resolve_include_path", @"stream_is_local", @"get_headers", @"stream_set_timeout", @"socket_set_timeout", @"socket_get_status", @"realpath", @"fnmatch", @"fsockopen", @"pfsockopen", @"pack", @"unpack", @"get_browser", @"crypt", @"opendir", @"closedir", @"chdir", @"getcwd", @"rewinddir", @"readdir", @"dir", @"scandir", @"glob", @"fileatime", @"filectime", @"filegroup", @"fileinode", @"filemtime", @"fileowner", @"fileperms", @"filesize", @"filetype", @"file_exists", @"is_writable", @"is_writeable", @"is_readable", @"is_executable", @"is_file", @"is_dir", @"is_link", @"stat", @"lstat", @"chown", @"chgrp", @"lchown", @"lchgrp", @"chmod", @"touch", @"clearstatcache", @"disk_total_space", @"disk_free_space", @"diskfreespace", @"realpath_cache_size", @"realpath_cache_get", @"mail", @"ezmlm_hash", @"openlog", @"syslog", @"closelog", @"define_syslog_variables", @"lcg_value", @"metaphone", @"ob_start", @"ob_flush", @"ob_clean", @"ob_end_flush", @"ob_end_clean", @"ob_get_flush", @"ob_get_clean", @"ob_get_length", @"ob_get_level", @"ob_get_status", @"ob_get_contents", @"ob_implicit_flush", @"ob_list_handlers", @"ksort", @"krsort", @"natsort", @"natcasesort", @"asort", @"arsort", @"sort", @"rsort", @"usort", @"uasort", @"uksort", @"shuffle", @"array_walk", @"array_walk_recursive", @"count", @"end", @"prev", @"next", @"reset", @"current", @"key", @"min", @"max", @"in_array", @"array_search", @"extract", @"compact", @"array_fill", @"array_fill_keys", @"range", @"array_multisort", @"array_push", @"array_pop", @"array_shift", @"array_unshift", @"array_splice", @"array_slice", @"array_merge", @"array_merge_recursive", @"array_replace", @"array_replace_recursive", @"array_keys", @"array_values", @"array_count_values", @"array_reverse", @"array_reduce", @"array_pad", @"array_flip", @"array_change_key_case", @"array_rand", @"array_unique", @"array_intersect", @"array_intersect_key", @"array_intersect_ukey", @"array_uintersect", @"array_intersect_assoc", @"array_uintersect_assoc", @"array_intersect_uassoc", @"array_uintersect_uassoc", @"array_diff", @"array_diff_key", @"array_diff_ukey", @"array_udiff", @"array_diff_assoc", @"array_udiff_assoc", @"array_diff_uassoc", @"array_udiff_uassoc", @"array_sum", @"array_product", @"array_filter", @"array_map", @"array_chunk", @"array_combine", @"array_key_exists", @"pos", @"sizeof", @"key_exists", @"assert", @"assert_options", @"version_compare", @"ftok", @"str_rot13", @"stream_get_filters", @"stream_filter_register", @"stream_bucket_make_writeable", @"stream_bucket_prepend", @"stream_bucket_append", @"stream_bucket_new", @"output_add_rewrite_var", @"output_reset_rewrite_vars", @"sys_get_temp_dir", @"token_get_all", @"token_name", @"xml_parser_create", @"xml_parser_create_ns", @"xml_set_object", @"xml_set_element_handler", @"xml_set_character_data_handler", @"xml_set_processing_instruction_handler", @"xml_set_default_handler", @"xml_set_unparsed_entity_decl_handler", @"xml_set_notation_decl_handler", @"xml_set_external_entity_ref_handler", @"xml_set_start_namespace_decl_handler", @"xml_set_end_namespace_decl_handler", @"xml_parse", @"xml_parse_into_struct", @"xml_get_error_code", @"xml_error_string", @"xml_get_current_line_number", @"xml_get_current_column_number", @"xml_get_current_byte_index", @"xml_parser_free", @"xml_parser_set_option", @"xml_parser_get_option", @"utf8_encode", @"utf8_decode", @"apache_lookup_uri", @"virtual", @"apache_request_headers", @"apache_response_headers", @"apache_setenv", @"apache_getenv", @"apache_note", @"apache_get_version", @"apache_get_modules", @"getallheaders", @"bcadd", @"bcsub", @"bcmul", @"bcdiv", @"bcmod", @"bcpow", @"bcsqrt", @"bcscale", @"bccomp", @"bcpowmod", @"curl_init", @"curl_copy_handle", @"curl_version", @"curl_setopt", @"curl_setopt_array", @"curl_exec", @"curl_getinfo", @"curl_error", @"curl_errno", @"curl_close", @"curl_multi_init", @"curl_multi_add_handle", @"curl_multi_remove_handle", @"curl_multi_select", @"curl_multi_exec", @"curl_multi_getcontent", @"curl_multi_info_read", @"curl_multi_close", @"dom_import_simplexml", @"finfo_open", @"finfo_close", @"finfo_set_flags", @"finfo_file", @"finfo_buffer", @"mime_content_type", @"gd_info", @"imagearc", @"imageellipse", @"imagechar", @"imagecharup", @"imagecolorat", @"imagecolorallocate", @"imagepalettecopy", @"imagecreatefromstring", @"imagecolorclosest", @"imagecolorclosesthwb", @"imagecolordeallocate", @"imagecolorresolve", @"imagecolorexact", @"imagecolorset", @"imagecolortransparent", @"imagecolorstotal", @"imagecolorsforindex", @"imagecopy", @"imagecopymerge", @"imagecopymergegray", @"imagecopyresized", @"imagecreate", @"imagecreatetruecolor", @"imageistruecolor", @"imagetruecolortopalette", @"imagesetthickness", @"imagefilledarc", @"imagefilledellipse", @"imagealphablending", @"imagesavealpha", @"imagecolorallocatealpha", @"imagecolorresolvealpha", @"imagecolorclosestalpha", @"imagecolorexactalpha", @"imagecopyresampled", @"imagerotate", @"imageantialias", @"imagesettile", @"imagesetbrush", @"imagesetstyle", @"imagecreatefrompng", @"imagecreatefromgif", @"imagecreatefromjpeg", @"imagecreatefromwbmp", @"imagecreatefromxbm", @"imagecreatefromxpm", @"imagecreatefromgd", @"imagecreatefromgd2", @"imagecreatefromgd2part", @"imagepng", @"imagegif", @"imagejpeg", @"imagewbmp", @"imagegd", @"imagegd2", @"imagedestroy", @"imagegammacorrect", @"imagefill", @"imagefilledpolygon", @"imagefilledrectangle", @"imagefilltoborder", @"imagefontwidth", @"imagefontheight", @"imageinterlace", @"imageline", @"imageloadfont", @"imagepolygon", @"imagerectangle", @"imagesetpixel", @"imagestring", @"imagestringup", @"imagesx", @"imagesy", @"imagedashedline", @"imagettfbbox", @"imagettftext", @"imageftbbox", @"imagefttext", @"imagetypes", @"jpeg2wbmp", @"png2wbmp", @"image2wbmp", @"imagelayereffect", @"imagexbm", @"imagecolormatch", @"imagefilter", @"imageconvolution", @"imap_open", @"imap_reopen", @"imap_close", @"imap_num_msg", @"imap_num_recent", @"imap_headers", @"imap_headerinfo", @"imap_rfc822_parse_headers", @"imap_rfc822_write_address", @"imap_rfc822_parse_adrlist", @"imap_body", @"imap_bodystruct", @"imap_fetchbody", @"imap_savebody", @"imap_fetchheader", @"imap_fetchstructure", @"imap_gc", @"imap_expunge", @"imap_delete", @"imap_undelete", @"imap_check", @"imap_listscan", @"imap_mail_copy", @"imap_mail_move", @"imap_mail_compose", @"imap_createmailbox", @"imap_renamemailbox", @"imap_deletemailbox", @"imap_subscribe", @"imap_unsubscribe", @"imap_append", @"imap_ping", @"imap_base64", @"imap_qprint", @"imap_8bit", @"imap_binary", @"imap_utf8", @"imap_status", @"imap_mailboxmsginfo", @"imap_setflag_full", @"imap_clearflag_full", @"imap_sort", @"imap_uid", @"imap_msgno", @"imap_list", @"imap_lsub", @"imap_fetch_overview", @"imap_alerts", @"imap_errors", @"imap_last_error", @"imap_search", @"imap_utf7_decode", @"imap_utf7_encode", @"imap_utf8_to_mutf7", @"imap_mutf7_to_utf8", @"imap_mime_header_decode", @"imap_thread", @"imap_timeout", @"imap_get_quota", @"imap_get_quotaroot", @"imap_set_quota", @"imap_setacl", @"imap_getacl", @"imap_mail", @"imap_header", @"imap_listmailbox", @"imap_getmailboxes", @"imap_scanmailbox", @"imap_listsubscribed", @"imap_getsubscribed", @"imap_fetchtext", @"imap_scan", @"imap_create", @"imap_rename", @"json_encode", @"json_decode", @"json_last_error", @"ldap_connect", @"ldap_close", @"ldap_bind", @"ldap_sasl_bind", @"ldap_unbind", @"ldap_read", @"ldap_list", @"ldap_search", @"ldap_free_result", @"ldap_count_entries", @"ldap_first_entry", @"ldap_next_entry", @"ldap_get_entries", @"ldap_first_attribute", @"ldap_next_attribute", @"ldap_get_attributes", @"ldap_get_values", @"ldap_get_values_len", @"ldap_get_dn", @"ldap_explode_dn", @"ldap_dn2ufn", @"ldap_add", @"ldap_delete", @"ldap_modify", @"ldap_mod_add", @"ldap_mod_replace", @"ldap_mod_del", @"ldap_errno", @"ldap_err2str", @"ldap_error", @"ldap_compare", @"ldap_sort", @"ldap_rename", @"ldap_get_option", @"ldap_set_option", @"ldap_first_reference", @"ldap_next_reference", @"ldap_parse_reference", @"ldap_parse_result", @"ldap_start_tls", @"ldap_set_rebind_proc", @"mb_convert_case", @"mb_strtoupper", @"mb_strtolower", @"mb_language", @"mb_internal_encoding", @"mb_http_input", @"mb_http_output", @"mb_detect_order", @"mb_substitute_character", @"mb_parse_str", @"mb_output_handler", @"mb_preferred_mime_name", @"mb_strlen", @"mb_strpos", @"mb_strrpos", @"mb_stripos", @"mb_strripos", @"mb_strstr", @"mb_strrchr", @"mb_stristr", @"mb_strrichr", @"mb_substr_count", @"mb_substr", @"mb_strcut", @"mb_strwidth", @"mb_strimwidth", @"mb_convert_encoding", @"mb_detect_encoding", @"mb_list_encodings", @"mb_encoding_aliases", @"mb_convert_kana", @"mb_encode_mimeheader", @"mb_decode_mimeheader", @"mb_convert_variables", @"mb_encode_numericentity", @"mb_decode_numericentity", @"mb_send_mail", @"mb_get_info", @"mb_check_encoding", @"mb_regex_encoding", @"mb_regex_set_options", @"mb_ereg", @"mb_eregi", @"mb_ereg_replace", @"mb_eregi_replace", @"mb_split", @"mb_ereg_match", @"mb_ereg_search", @"mb_ereg_search_pos", @"mb_ereg_search_regs", @"mb_ereg_search_init", @"mb_ereg_search_getregs", @"mb_ereg_search_getpos", @"mb_ereg_search_setpos", @"mbregex_encoding", @"mbereg", @"mberegi", @"mbereg_replace", @"mberegi_replace", @"mbsplit", @"mbereg_match", @"mbereg_search", @"mbereg_search_pos", @"mbereg_search_regs", @"mbereg_search_init", @"mbereg_search_getregs", @"mbereg_search_getpos", @"mbereg_search_setpos", @"mcrypt_ecb", @"mcrypt_cbc", @"mcrypt_cfb", @"mcrypt_ofb", @"mcrypt_get_key_size", @"mcrypt_get_block_size", @"mcrypt_get_cipher_name", @"mcrypt_create_iv", @"mcrypt_list_algorithms", @"mcrypt_list_modes", @"mcrypt_get_iv_size", @"mcrypt_encrypt", @"mcrypt_decrypt", @"mcrypt_module_open", @"mcrypt_generic_init", @"mcrypt_generic", @"mdecrypt_generic", @"mcrypt_generic_end", @"mcrypt_generic_deinit", @"mcrypt_enc_self_test", @"mcrypt_enc_is_block_algorithm_mode", @"mcrypt_enc_is_block_algorithm", @"mcrypt_enc_is_block_mode", @"mcrypt_enc_get_block_size", @"mcrypt_enc_get_key_size", @"mcrypt_enc_get_supported_key_sizes", @"mcrypt_enc_get_iv_size", @"mcrypt_enc_get_algorithms_name", @"mcrypt_enc_get_modes_name", @"mcrypt_module_self_test", @"mcrypt_module_is_block_algorithm_mode", @"mcrypt_module_is_block_algorithm", @"mcrypt_module_is_block_mode", @"mcrypt_module_get_algo_block_size", @"mcrypt_module_get_algo_key_size", @"mcrypt_module_get_supported_key_sizes", @"mcrypt_module_close", @"mysql_connect", @"mysql_pconnect", @"mysql_close", @"mysql_select_db", @"mysql_query", @"mysql_unbuffered_query", @"mysql_db_query", @"mysql_list_dbs", @"mysql_list_tables", @"mysql_list_fields", @"mysql_list_processes", @"mysql_error", @"mysql_errno", @"mysql_affected_rows", @"mysql_insert_id", @"mysql_result", @"mysql_num_rows", @"mysql_num_fields", @"mysql_fetch_row", @"mysql_fetch_array", @"mysql_fetch_assoc", @"mysql_fetch_object", @"mysql_data_seek", @"mysql_fetch_lengths", @"mysql_fetch_field", @"mysql_field_seek", @"mysql_free_result", @"mysql_field_name", @"mysql_field_table", @"mysql_field_len", @"mysql_field_type", @"mysql_field_flags", @"mysql_escape_string", @"mysql_real_escape_string", @"mysql_stat", @"mysql_thread_id", @"mysql_client_encoding", @"mysql_ping", @"mysql_get_client_info", @"mysql_get_host_info", @"mysql_get_proto_info", @"mysql_get_server_info", @"mysql_info", @"mysql_set_charset", @"mysql", @"mysql_fieldname", @"mysql_fieldtable", @"mysql_fieldlen", @"mysql_fieldtype", @"mysql_fieldflags", @"mysql_selectdb", @"mysql_freeresult", @"mysql_numfields", @"mysql_numrows", @"mysql_listdbs", @"mysql_listtables", @"mysql_listfields", @"mysql_db_name", @"mysql_dbname", @"mysql_tablename", @"mysql_table_name", @"mysqli_affected_rows", @"mysqli_autocommit", @"mysqli_change_user", @"mysqli_character_set_name", @"mysqli_close", @"mysqli_commit", @"mysqli_connect", @"mysqli_connect_errno", @"mysqli_connect_error", @"mysqli_data_seek", @"mysqli_dump_debug_info", @"mysqli_debug", @"mysqli_errno", @"mysqli_error", @"mysqli_stmt_execute", @"mysqli_execute", @"mysqli_fetch_field", @"mysqli_fetch_fields", @"mysqli_fetch_field_direct", @"mysqli_fetch_lengths", @"mysqli_fetch_array", @"mysqli_fetch_assoc", @"mysqli_fetch_object", @"mysqli_fetch_row", @"mysqli_field_count", @"mysqli_field_seek", @"mysqli_field_tell", @"mysqli_free_result", @"mysqli_get_charset", @"mysqli_get_client_info", @"mysqli_get_client_version", @"mysqli_get_host_info", @"mysqli_get_proto_info", @"mysqli_get_server_info", @"mysqli_get_server_version", @"mysqli_get_warnings", @"mysqli_init", @"mysqli_info", @"mysqli_insert_id", @"mysqli_kill", @"mysqli_set_local_infile_default", @"mysqli_set_local_infile_handler", @"mysqli_more_results", @"mysqli_multi_query", @"mysqli_next_result", @"mysqli_num_fields", @"mysqli_num_rows", @"mysqli_options", @"mysqli_ping", @"mysqli_prepare", @"mysqli_report", @"mysqli_query", @"mysqli_real_connect", @"mysqli_real_escape_string", @"mysqli_real_query", @"mysqli_rollback", @"mysqli_select_db", @"mysqli_set_charset", @"mysqli_stmt_affected_rows", @"mysqli_stmt_attr_get", @"mysqli_stmt_attr_set", @"mysqli_stmt_bind_param", @"mysqli_stmt_bind_result", @"mysqli_stmt_close", @"mysqli_stmt_data_seek", @"mysqli_stmt_errno", @"mysqli_stmt_error", @"mysqli_stmt_fetch", @"mysqli_stmt_field_count", @"mysqli_stmt_free_result", @"mysqli_stmt_get_warnings", @"mysqli_stmt_init", @"mysqli_stmt_insert_id", @"mysqli_stmt_num_rows", @"mysqli_stmt_param_count", @"mysqli_stmt_prepare", @"mysqli_stmt_reset", @"mysqli_stmt_result_metadata", @"mysqli_stmt_send_long_data", @"mysqli_stmt_store_result", @"mysqli_stmt_sqlstate", @"mysqli_sqlstate", @"mysqli_ssl_set", @"mysqli_stat", @"mysqli_store_result", @"mysqli_thread_id", @"mysqli_thread_safe", @"mysqli_use_result", @"mysqli_warning_count", @"mysqli_refresh", @"mysqli_bind_param", @"mysqli_bind_result", @"mysqli_client_encoding", @"mysqli_escape_string", @"mysqli_fetch", @"mysqli_param_count", @"mysqli_get_metadata", @"mysqli_send_long_data", @"mysqli_set_opt", @"odbc_autocommit", @"odbc_binmode", @"odbc_close", @"odbc_close_all", @"odbc_columns", @"odbc_commit", @"odbc_connect", @"odbc_cursor", @"odbc_data_source", @"odbc_execute", @"odbc_error", @"odbc_errormsg", @"odbc_exec", @"odbc_fetch_array", @"odbc_fetch_object", @"odbc_fetch_row", @"odbc_fetch_into", @"odbc_field_len", @"odbc_field_scale", @"odbc_field_name", @"odbc_field_type", @"odbc_field_num", @"odbc_free_result", @"odbc_gettypeinfo", @"odbc_longreadlen", @"odbc_next_result", @"odbc_num_fields", @"odbc_num_rows", @"odbc_pconnect", @"odbc_prepare", @"odbc_result", @"odbc_result_all", @"odbc_rollback", @"odbc_setoption", @"odbc_specialcolumns", @"odbc_statistics", @"odbc_tables", @"odbc_primarykeys", @"odbc_columnprivileges", @"odbc_tableprivileges", @"odbc_foreignkeys", @"odbc_procedures", @"odbc_procedurecolumns", @"odbc_do", @"odbc_field_precision", @"pdo_drivers", @"use_soap_error_handler", @"is_soap_fault", @"ssh2_connect", @"ssh2_methods_negotiated", @"ssh2_fingerprint", @"ssh2_auth_none", @"ssh2_auth_password", @"ssh2_auth_pubkey_file", @"ssh2_auth_hostbased_file", @"ssh2_forward_listen", @"ssh2_forward_accept", @"ssh2_shell", @"ssh2_exec", @"ssh2_tunnel", @"ssh2_scp_recv", @"ssh2_scp_send", @"ssh2_fetch_stream", @"ssh2_poll", @"ssh2_sftp", @"ssh2_sftp_rename", @"ssh2_sftp_unlink", @"ssh2_sftp_mkdir", @"ssh2_sftp_rmdir", @"ssh2_sftp_chmod", @"ssh2_sftp_stat", @"ssh2_sftp_lstat", @"ssh2_sftp_symlink", @"ssh2_sftp_readlink", @"ssh2_sftp_realpath", @"ssh2_publickey_init", @"ssh2_publickey_add", @"ssh2_publickey_remove", @"ssh2_publickey_list", @"ssh2_auth_agent", @"svn_checkout", @"svn_cat", @"svn_ls", @"svn_log", @"svn_auth_set_parameter", @"svn_auth_get_parameter", @"svn_client_version", @"svn_config_ensure", @"svn_diff", @"svn_cleanup", @"svn_revert", @"svn_resolved", @"svn_commit", @"svn_lock", @"svn_unlock", @"svn_add", @"svn_status", @"svn_update", @"svn_import", @"svn_info", @"svn_export", @"svn_copy", @"svn_switch", @"svn_blame", @"svn_delete", @"svn_mkdir", @"svn_move", @"svn_proplist", @"svn_propget", @"svn_repos_create", @"svn_repos_recover", @"svn_repos_hotcopy", @"svn_repos_open", @"svn_repos_fs", @"svn_repos_fs_begin_txn_for_commit", @"svn_repos_fs_commit_txn", @"svn_fs_revision_root", @"svn_fs_check_path", @"svn_fs_revision_prop", @"svn_fs_dir_entries", @"svn_fs_node_created_rev", @"svn_fs_youngest_rev", @"svn_fs_file_contents", @"svn_fs_file_length", @"svn_fs_txn_root", @"svn_fs_make_file", @"svn_fs_make_dir", @"svn_fs_apply_text", @"svn_fs_copy", @"svn_fs_delete", @"svn_fs_begin_txn2", @"svn_fs_is_dir", @"svn_fs_is_file", @"svn_fs_node_prop", @"svn_fs_change_node_prop", @"svn_fs_contents_changed", @"svn_fs_props_changed", @"svn_fs_abort_txn", @"wddx_serialize_value", @"wddx_serialize_vars", @"wddx_packet_start", @"wddx_packet_end", @"wddx_add_vars", @"wddx_deserialize", @"xhprof_enable", @"xhprof_disable", @"xhprof_sample_enable", @"xhprof_sample_disable", @"xmlrpc_encode", @"xmlrpc_decode", @"xmlrpc_decode_request", @"xmlrpc_encode_request", @"xmlrpc_get_type", @"xmlrpc_set_type", @"xmlrpc_is_fault", @"xmlrpc_server_create", @"xmlrpc_server_destroy", @"xmlrpc_server_register_method", @"xmlrpc_server_call_method", @"xmlrpc_parse_method_descriptions", @"xmlrpc_server_add_introspection_data", @"xmlrpc_server_register_introspection_callback", @"xmlwriter_open_uri", @"xmlwriter_open_memory", @"xmlwriter_set_indent", @"xmlwriter_set_indent_string", @"xmlwriter_start_comment", @"xmlwriter_end_comment", @"xmlwriter_start_attribute", @"xmlwriter_end_attribute", @"xmlwriter_write_attribute", @"xmlwriter_start_attribute_ns", @"xmlwriter_write_attribute_ns", @"xmlwriter_start_element", @"xmlwriter_end_element", @"xmlwriter_full_end_element", @"xmlwriter_start_element_ns", @"xmlwriter_write_element", @"xmlwriter_write_element_ns", @"xmlwriter_start_pi", @"xmlwriter_end_pi", @"xmlwriter_write_pi", @"xmlwriter_start_cdata", @"xmlwriter_end_cdata", @"xmlwriter_write_cdata", @"xmlwriter_text", @"xmlwriter_write_raw", @"xmlwriter_start_document", @"xmlwriter_end_document", @"xmlwriter_write_comment", @"xmlwriter_start_dtd", @"xmlwriter_end_dtd", @"xmlwriter_write_dtd", @"xmlwriter_start_dtd_element", @"xmlwriter_end_dtd_element", @"xmlwriter_write_dtd_element", @"xmlwriter_start_dtd_attlist", @"xmlwriter_end_dtd_attlist", @"xmlwriter_write_dtd_attlist", @"xmlwriter_start_dtd_entity", @"xmlwriter_end_dtd_entity", @"xmlwriter_write_dtd_entity", @"xmlwriter_output_memory", @"xmlwriter_flush", @"zip_open", @"zip_close", @"zip_read", @"zip_entry_open", @"zip_entry_close", @"zip_entry_read", @"zip_entry_filesize", @"zip_entry_name", @"zip_entry_compressedsize", @"zip_entry_compressionmethod", @"ioncube_file_is_encoded", @"ioncube_file_info", @"ioncube_file_properties", @"ioncube_file_not_permissioned", @"ioncube_license_properties", @"ioncube_licensed_servers", @"ioncube_server_data", @"_dyuweyrj4", @"_dyuweyrj4r", @"ioncube_check_license_properties", @"ioncube_license_matches_server", @"ioncube_license_has_expired", @"ioncube_read_file", @"ioncube_write_file", @"ioncube_loader_version", @"ioncube_loader_iversion"]];
    
    set = mutableSet.copy;
  });
  
  return set;
}

@end
