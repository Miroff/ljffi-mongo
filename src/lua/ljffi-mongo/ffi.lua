--------------------------------------------------------------------------------
--- Low-level FFI bindings to MongoDB C driver.
-- @module ljffi-mongo.ffi
-- This file is a part of ljffi-mongo  library
-- @copyright ljffi-mongo  authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local ffi = require("ffi")

--------------------------------------------------------------------------------

local mongo = ffi.load("mongoc")

--------------------------------------------------------------------------------
-- Based on Apache 2.0 licensed mongo.h and bson.h from mongo-c-driver v0.7.1
-- https://github.com/mongodb/mongo-c-driver
--------------------------------------------------------------------------------

ffi.cdef [[
typedef long time_t;
typedef int FILE;

/* Excerpt from bson.h */

enum {
  BSON_OK = 0,
  BSON_ERROR = -1 
};

enum bson_error_t {
    BSON_SIZE_OVERFLOW = 1 /**< Trying to create a BSON object larger than INT_MAX. */
};

enum bson_validity_t {
    BSON_VALID = 0,                 /**< BSON is valid and UTF-8 compliant. */
    BSON_NOT_UTF8 = ( 1<<1 ),       /**< A key or a string is not valid UTF-8. */
    BSON_FIELD_HAS_DOT = ( 1<<2 ),  /**< Warning: key contains '.' character. */
    BSON_FIELD_INIT_DOLLAR = ( 1<<3 ), /**< Warning: key starts with '$' character. */
    BSON_ALREADY_FINISHED = ( 1<<4 )  /**< Trying to modify a finished BSON object. */
};

enum bson_binary_subtype_t {
    BSON_BIN_BINARY = 0,
    BSON_BIN_FUNC = 1,
    BSON_BIN_BINARY_OLD = 2,
    BSON_BIN_UUID = 3,
    BSON_BIN_MD5 = 5,
    BSON_BIN_USER = 128
};

typedef enum {
    BSON_EOO = 0,
    BSON_DOUBLE = 1,
    BSON_STRING = 2,
    BSON_OBJECT = 3,
    BSON_ARRAY = 4,
    BSON_BINDATA = 5,
    BSON_UNDEFINED = 6,
    BSON_OID = 7,
    BSON_BOOL = 8,
    BSON_DATE = 9,
    BSON_NULL = 10,
    BSON_REGEX = 11,
    BSON_DBREF = 12, /**< Deprecated. */
    BSON_CODE = 13,
    BSON_SYMBOL = 14,
    BSON_CODEWSCOPE = 15,
    BSON_INT = 16,
    BSON_TIMESTAMP = 17,
    BSON_LONG = 18
} bson_type;

typedef int bson_bool_t;

typedef struct {
    const char *cur;
    bson_bool_t first;
} bson_iterator;

typedef struct {
    char *data;    /**< Pointer to a block of data in this BSON object. */
    char *cur;     /**< Pointer to the current position. */
    int dataSize;  /**< The number of bytes allocated to char *data. */
    bson_bool_t finished; /**< When finished, the BSON object can no longer be modified. */
    int stack[32];        /**< A stack used to keep track of nested BSON elements. */
    int stackPos;         /**< Index of current stack position. */
    int err; /**< Bitfield representing errors or warnings on this buffer */
    char *errstr; /**< A string representation of the most recent error or warning. */
} bson;

#pragma pack(1)
typedef union {
    char bytes[12];
    int ints[3];
} bson_oid_t;
#pragma pack()

typedef int64_t bson_date_t; /* milliseconds since epoch UTC */

typedef struct {
    int i; /* increment */
    int t; /* time in seconds */
} bson_timestamp_t;

/* ----------------------------
   READING
   ------------------------------ */

bson* bson_create( void );
void  bson_dispose(bson* b);

/**
 * Size of a BSON object.
 *
 * @param b the BSON object.
 *
 * @return the size.
 */
int bson_size( const bson *b );
int bson_buffer_size( const bson *b );

/**
 * Print a string representation of a BSON object.
 *
 * @param b the BSON object to print.
 */
void bson_print( const bson *b );

/**
 * Return a pointer to the raw buffer stored by this bson object.
 *
 * @param b a BSON object
 */
const char *bson_data( const bson *b );

/**
 * Print a string representation of a BSON object.
 *
 * @param bson the raw data to print.
 * @param depth the depth to recurse the object.x
 */
void bson_print_raw( const char *bson , int depth );

/**
 * Advance a bson_iterator to the named field.
 *
 * @param it the bson_iterator to use.
 * @param obj the BSON object to use.
 * @param name the name of the field to find.
 *
 * @return the type of the found object or BSON_EOO if it is not found.
 */
bson_type bson_find( bson_iterator *it, const bson *obj, const char *name );


bson_iterator* bson_iterator_create( void );
void bson_iterator_dispose(bson_iterator*);
/**
 * Initialize a bson_iterator.
 *
 * @param i the bson_iterator to initialize.
 * @param bson the BSON object to associate with the iterator.
 */
void bson_iterator_init( bson_iterator *i , const bson *b );

/**
 * Initialize a bson iterator from a const char* buffer. Note
 * that this is mostly used internally.
 *
 * @param i the bson_iterator to initialize.
 * @param buffer the buffer to point to.
 */
void bson_iterator_from_buffer( bson_iterator *i, const char *buffer );

/* more returns true for eoo. best to loop with bson_iterator_next(&it) */
/**
 * Check to see if the bson_iterator has more data.
 *
 * @param i the iterator.
 *
 * @return  returns true if there is more data.
 */
bson_bool_t bson_iterator_more( const bson_iterator *i );

/**
 * Point the iterator at the next BSON object.
 *
 * @param i the bson_iterator.
 *
 * @return the type of the next BSON object.
 */
bson_type bson_iterator_next( bson_iterator *i );

/**
 * Get the type of the BSON object currently pointed to by the iterator.
 *
 * @param i the bson_iterator
 *
 * @return  the type of the current BSON object.
 */
bson_type bson_iterator_type( const bson_iterator *i );

/**
 * Get the key of the BSON object currently pointed to by the iterator.
 *
 * @param i the bson_iterator
 *
 * @return the key of the current BSON object.
 */
const char *bson_iterator_key( const bson_iterator *i );

/**
 * Get the value of the BSON object currently pointed to by the iterator.
 *
 * @param i the bson_iterator
 *
 * @return  the value of the current BSON object.
 */
const char *bson_iterator_value( const bson_iterator *i );

/* these convert to the right type (return 0 if non-numeric) */
/**
 * Get the double value of the BSON object currently pointed to by the
 * iterator.
 *
 * @param i the bson_iterator
 *
 * @return  the value of the current BSON object.
 */
double bson_iterator_double( const bson_iterator *i );

/**
 * Get the int value of the BSON object currently pointed to by the iterator.
 *
 * @param i the bson_iterator
 *
 * @return  the value of the current BSON object.
 */
int bson_iterator_int( const bson_iterator *i );

/**
 * Get the long value of the BSON object currently pointed to by the iterator.
 *
 * @param i the bson_iterator
 *
 * @return the value of the current BSON object.
 */
int64_t bson_iterator_long( const bson_iterator *i );

/* return the bson timestamp as a whole or in parts */
/**
 * Get the timestamp value of the BSON object currently pointed to by
 * the iterator.
 *
 * @param i the bson_iterator
 *
 * @return the value of the current BSON object.
 */
bson_timestamp_t bson_iterator_timestamp( const bson_iterator *i );
int bson_iterator_timestamp_time( const bson_iterator *i );
int bson_iterator_timestamp_increment( const bson_iterator *i );

/**
 * Get the boolean value of the BSON object currently pointed to by
 * the iterator.
 *
 * @param i the bson_iterator
 *
 * @return the value of the current BSON object.
 */
/* false: boolean false, 0 in any type, or null */
/* true: anything else (even empty strings and objects) */
bson_bool_t bson_iterator_bool( const bson_iterator *i );

/**
 * Get the double value of the BSON object currently pointed to by the
 * iterator. Assumes the correct type is used.
 *
 * @param i the bson_iterator
 *
 * @return the value of the current BSON object.
 */
/* these assume you are using the right type */
double bson_iterator_double_raw( const bson_iterator *i );

/**
 * Get the int value of the BSON object currently pointed to by the
 * iterator. Assumes the correct type is used.
 *
 * @param i the bson_iterator
 *
 * @return the value of the current BSON object.
 */
int bson_iterator_int_raw( const bson_iterator *i );

/**
 * Get the long value of the BSON object currently pointed to by the
 * iterator. Assumes the correct type is used.
 *
 * @param i the bson_iterator
 *
 * @return the value of the current BSON object.
 */
int64_t bson_iterator_long_raw( const bson_iterator *i );

/**
 * Get the bson_bool_t value of the BSON object currently pointed to by the
 * iterator. Assumes the correct type is used.
 *
 * @param i the bson_iterator
 *
 * @return the value of the current BSON object.
 */
bson_bool_t bson_iterator_bool_raw( const bson_iterator *i );

/**
 * Get the bson_oid_t value of the BSON object currently pointed to by the
 * iterator.
 *
 * @param i the bson_iterator
 *
 * @return the value of the current BSON object.
 */
bson_oid_t *bson_iterator_oid( const bson_iterator *i );

/**
 * Get the string value of the BSON object currently pointed to by the
 * iterator.
 *
 * @param i the bson_iterator
 *
 * @return  the value of the current BSON object.
 */
/* these can also be used with bson_code and bson_symbol*/
const char *bson_iterator_string( const bson_iterator *i );

/**
 * Get the string length of the BSON object currently pointed to by the
 * iterator.
 *
 * @param i the bson_iterator
 *
 * @return the length of the current BSON object.
 */
int bson_iterator_string_len( const bson_iterator *i );

/**
 * Get the code value of the BSON object currently pointed to by the
 * iterator. Works with bson_code, bson_codewscope, and BSON_STRING
 * returns NULL for everything else.
 *
 * @param i the bson_iterator
 *
 * @return the code value of the current BSON object.
 */
/* works with bson_code, bson_codewscope, and BSON_STRING */
/* returns NULL for everything else */
const char *bson_iterator_code( const bson_iterator *i );

/**
 * Calls bson_empty on scope if not a bson_codewscope
 *
 * @param i the bson_iterator.
 * @param scope the bson scope.
 */
/* calls bson_empty on scope if not a bson_codewscope */
void bson_iterator_code_scope( const bson_iterator *i, bson *scope );

/**
 * Get the date value of the BSON object currently pointed to by the
 * iterator.
 *
 * @param i the bson_iterator
 *
 * @return the date value of the current BSON object.
 */
/* both of these only work with bson_date */
bson_date_t bson_iterator_date( const bson_iterator *i );

/**
 * Get the time value of the BSON object currently pointed to by the
 * iterator.
 *
 * @param i the bson_iterator
 *
 * @return the time value of the current BSON object.
 */
time_t bson_iterator_time_t( const bson_iterator *i );

/**
 * Get the length of the BSON binary object currently pointed to by the
 * iterator.
 *
 * @param i the bson_iterator
 *
 * @return the length of the current BSON binary object.
 */
int bson_iterator_bin_len( const bson_iterator *i );

/**
 * Get the type of the BSON binary object currently pointed to by the
 * iterator.
 *
 * @param i the bson_iterator
 *
 * @return the type of the current BSON binary object.
 */
char bson_iterator_bin_type( const bson_iterator *i );

/**
 * Get the value of the BSON binary object currently pointed to by the
 * iterator.
 *
 * @param i the bson_iterator
 *
 * @return the value of the current BSON binary object.
 */
const char *bson_iterator_bin_data( const bson_iterator *i );

/**
 * Get the value of the BSON regex object currently pointed to by the
 * iterator.
 *
 * @param i the bson_iterator
 *
 * @return the value of the current BSON regex object.
 */
const char *bson_iterator_regex( const bson_iterator *i );

/**
 * Get the options of the BSON regex object currently pointed to by the
 * iterator.
 *
 * @param i the bson_iterator.
 *
 * @return the options of the current BSON regex object.
 */
const char *bson_iterator_regex_opts( const bson_iterator *i );

/* these work with BSON_OBJECT and BSON_ARRAY */
/**
 * Get the BSON subobject currently pointed to by the
 * iterator.
 *
 * @param i the bson_iterator.
 * @param sub the BSON subobject destination.
 */
void bson_iterator_subobject( const bson_iterator *i, bson *sub );

/**
 * Get a bson_iterator that on the BSON subobject.
 *
 * @param i the bson_iterator.
 * @param sub the iterator to point at the BSON subobject.
 */
void bson_iterator_subiterator( const bson_iterator *i, bson_iterator *sub );

/* str must be at least 24 hex chars + null byte */
/**
 * Create a bson_oid_t from a string.
 *
 * @param oid the bson_oid_t destination.
 * @param str a null terminated string comprised of at least 24 hex chars.
 */
void bson_oid_from_string( bson_oid_t *oid, const char *str );

/**
 * Create a string representation of the bson_oid_t.
 *
 * @param oid the bson_oid_t source.
 * @param str the string representation destination.
 */
void bson_oid_to_string( const bson_oid_t *oid, char *str );

/**
 * Create a bson_oid object.
 *
 * @param oid the destination for the newly created bson_oid_t.
 */
void bson_oid_gen( bson_oid_t *oid );

/**
 * Set a function to be used to generate the second four bytes
 * of an object id.
 *
 * @param func a pointer to a function that returns an int.
 */
void bson_set_oid_fuzz( int ( *func )( void ) );

/**
 * Set a function to be used to generate the incrementing part
 * of an object id (last four bytes). If you need thread-safety
 * in generating object ids, you should set this function.
 *
 * @param func a pointer to a function that returns an int.
 */
void bson_set_oid_inc( int ( *func )( void ) );

/**
 * Get the time a bson_oid_t was created.
 *
 * @param oid the bson_oid_t.
 */
time_t bson_oid_generated_time( bson_oid_t *oid ); /* Gives the time the OID was created */

/* ----------------------------
   BUILDING
   ------------------------------ */

/**
 *  Initialize a new bson object. If not created
 *  with bson_new, you must initialize each new bson
 *  object using this function.
 *
 *  @note When finished, you must pass the bson object to
 *      bson_destroy( ).
 */
void bson_init( bson *b );

/**
 * Initialize a BSON object, and point its data
 * pointer to the provided char*.
 *
 * @param b the BSON object to initialize.
 * @param data the raw BSON data.
 *
 * @return BSON_OK or BSON_ERROR.
 */
int bson_init_data( bson *b , char *data );
int bson_init_finished_data( bson *b, char *data ) ;

/**
 * Initialize a BSON object, and set its
 * buffer to the given size.
 *
 * @param b the BSON object to initialize.
 * @param size the initial size of the buffer.
 *
 * @return BSON_OK or BSON_ERROR.
 */
void bson_init_size( bson *b, int size );

/**
 * Grow a bson object.
 *
 * @param b the bson to grow.
 * @param bytesNeeded the additional number of bytes needed.
 *
 * @return BSON_OK or BSON_ERROR with the bson error object set.
 *   Exits if allocation fails.
 */
int bson_ensure_space( bson *b, const int bytesNeeded );

/**
 * Finalize a bson object.
 *
 * @param b the bson object to finalize.
 *
 * @return the standard error code. To deallocate memory,
 *   call bson_destroy on the bson object.
 */
int bson_finish( bson *b );

/**
 * Destroy a bson object.
 *
 * @param b the bson object to destroy.
 *
 */
void bson_destroy( bson *b );

/**
 * Returns a pointer to a static empty BSON object.
 *
 * @param obj the BSON object to initialize.
 *
 * @return the empty initialized BSON object.
 */
/* returns pointer to static empty bson object */
bson *bson_empty( bson *obj );

/**
 * Make a complete copy of the a BSON object.
 * The source bson object must be in a finished
 * state; otherwise, the copy will fail.
 *
 * @param out the copy destination BSON object.
 * @param in the copy source BSON object.
 */
int bson_copy( bson *out, const bson *in ); /* puts data in new buffer. NOOP if out==NULL */

/**
 * Append a previously created bson_oid_t to a bson object.
 *
 * @param b the bson to append to.
 * @param name the key for the bson_oid_t.
 * @param oid the bson_oid_t to append.
 *
 * @return BSON_OK or BSON_ERROR.
 */
int bson_append_oid( bson *b, const char *name, const bson_oid_t *oid );

/**
 * Append a bson_oid_t to a bson.
 *
 * @param b the bson to append to.
 * @param name the key for the bson_oid_t.
 *
 * @return BSON_OK or BSON_ERROR.
 */
int bson_append_new_oid( bson *b, const char *name );

/**
 * Append an int to a bson.
 *
 * @param b the bson to append to.
 * @param name the key for the int.
 * @param i the int to append.
 *
 * @return BSON_OK or BSON_ERROR.
 */
int bson_append_int( bson *b, const char *name, const int i );

/**
 * Append an long to a bson.
 *
 * @param b the bson to append to.
 * @param name the key for the long.
 * @param i the long to append.
 *
 * @return BSON_OK or BSON_ERROR.
 */
int bson_append_long( bson *b, const char *name, const int64_t i );

/**
 * Append an double to a bson.
 *
 * @param b the bson to append to.
 * @param name the key for the double.
 * @param d the double to append.
 *
 * @return BSON_OK or BSON_ERROR.
 */
int bson_append_double( bson *b, const char *name, const double d );

/**
 * Append a string to a bson.
 *
 * @param b the bson to append to.
 * @param name the key for the string.
 * @param str the string to append.
 *
 * @return BSON_OK or BSON_ERROR.
*/
int bson_append_string( bson *b, const char *name, const char *str );

/**
 * Append len bytes of a string to a bson.
 *
 * @param b the bson to append to.
 * @param name the key for the string.
 * @param str the string to append.
 * @param len the number of bytes from str to append.
 *
 * @return BSON_OK or BSON_ERROR.
 */
int bson_append_string_n( bson *b, const char *name, const char *str, int len );

/**
 * Append a symbol to a bson.
 *
 * @param b the bson to append to.
 * @param name the key for the symbol.
 * @param str the symbol to append.
 *
 * @return BSON_OK or BSON_ERROR.
 */
int bson_append_symbol( bson *b, const char *name, const char *str );

/**
 * Append len bytes of a symbol to a bson.
 *
 * @param b the bson to append to.
 * @param name the key for the symbol.
 * @param str the symbol to append.
 * @param len the number of bytes from str to append.
 *
 * @return BSON_OK or BSON_ERROR.
 */
int bson_append_symbol_n( bson *b, const char *name, const char *str, int len );

/**
 * Append code to a bson.
 *
 * @param b the bson to append to.
 * @param name the key for the code.
 * @param str the code to append.
 * @param len the number of bytes from str to append.
 *
 * @return BSON_OK or BSON_ERROR.
 */
int bson_append_code( bson *b, const char *name, const char *str );

/**
 * Append len bytes of code to a bson.
 *
 * @param b the bson to append to.
 * @param name the key for the code.
 * @param str the code to append.
 * @param len the number of bytes from str to append.
 *
 * @return BSON_OK or BSON_ERROR.
 */
int bson_append_code_n( bson *b, const char *name, const char *str, int len );

/**
 * Append code to a bson with scope.
 *
 * @param b the bson to append to.
 * @param name the key for the code.
 * @param str the string to append.
 * @param scope a BSON object containing the scope.
 *
 * @return BSON_OK or BSON_ERROR.
 */
int bson_append_code_w_scope( bson *b, const char *name, const char *code, const bson *scope );

/**
 * Append len bytes of code to a bson with scope.
 *
 * @param b the bson to append to.
 * @param name the key for the code.
 * @param str the string to append.
 * @param len the number of bytes from str to append.
 * @param scope a BSON object containing the scope.
 *
 * @return BSON_OK or BSON_ERROR.
 */
int bson_append_code_w_scope_n( bson *b, const char *name, const char *code, int size, const bson *scope );

/**
 * Append binary data to a bson.
 *
 * @param b the bson to append to.
 * @param name the key for the data.
 * @param type the binary data type.
 * @param str the binary data.
 * @param len the length of the data.
 *
 * @return BSON_OK or BSON_ERROR.
 */
int bson_append_binary( bson *b, const char *name, char type, const char *str, int len );

/**
 * Append a bson_bool_t to a bson.
 *
 * @param b the bson to append to.
 * @param name the key for the boolean value.
 * @param v the bson_bool_t to append.
 *
 * @return BSON_OK or BSON_ERROR.
 */
int bson_append_bool( bson *b, const char *name, const bson_bool_t v );

/**
 * Append a null value to a bson.
 *
 * @param b the bson to append to.
 * @param name the key for the null value.
 *
 * @return BSON_OK or BSON_ERROR.
 */
int bson_append_null( bson *b, const char *name );

/**
 * Append an undefined value to a bson.
 *
 * @param b the bson to append to.
 * @param name the key for the undefined value.
 *
 * @return BSON_OK or BSON_ERROR.
 */
int bson_append_undefined( bson *b, const char *name );

/**
 * Append a regex value to a bson.
 *
 * @param b the bson to append to.
 * @param name the key for the regex value.
 * @param pattern the regex pattern to append.
 * @param the regex options.
 *
 * @return BSON_OK or BSON_ERROR.
 */
int bson_append_regex( bson *b, const char *name, const char *pattern, const char *opts );

/**
 * Append bson data to a bson.
 *
 * @param b the bson to append to.
 * @param name the key for the bson data.
 * @param bson the bson object to append.
 *
 * @return BSON_OK or BSON_ERROR.
 */
int bson_append_bson( bson *b, const char *name, const bson *bson );

/**
 * Append a BSON element to a bson from the current point of an iterator.
 *
 * @param b the bson to append to.
 * @param name_or_null the key for the BSON element, or NULL.
 * @param elem the bson_iterator.
 *
 * @return BSON_OK or BSON_ERROR.
 */
int bson_append_element( bson *b, const char *name_or_null, const bson_iterator *elem );

/**
 * Append a bson_timestamp_t value to a bson.
 *
 * @param b the bson to append to.
 * @param name the key for the timestampe value.
 * @param ts the bson_timestamp_t value to append.
 *
 * @return BSON_OK or BSON_ERROR.
 */
int bson_append_timestamp( bson *b, const char *name, bson_timestamp_t *ts );
int bson_append_timestamp2( bson *b, const char *name, int time, int increment );

/* these both append a bson_date */
/**
 * Append a bson_date_t value to a bson.
 *
 * @param b the bson to append to.
 * @param name the key for the date value.
 * @param millis the bson_date_t to append.
 *
 * @return BSON_OK or BSON_ERROR.
 */
int bson_append_date( bson *b, const char *name, bson_date_t millis );

/**
 * Append a time_t value to a bson.
 *
 * @param b the bson to append to.
 * @param name the key for the date value.
 * @param secs the time_t to append.
 *
 * @return BSON_OK or BSON_ERROR.
 */
int bson_append_time_t( bson *b, const char *name, time_t secs );

/**
 * Start appending a new object to a bson.
 *
 * @param b the bson to append to.
 * @param name the name of the new object.
 *
 * @return BSON_OK or BSON_ERROR.
 */
int bson_append_start_object( bson *b, const char *name );

/**
 * Start appending a new array to a bson.
 *
 * @param b the bson to append to.
 * @param name the name of the new array.
 *
 * @return BSON_OK or BSON_ERROR.
 */
int bson_append_start_array( bson *b, const char *name );

/**
 * Finish appending a new object or array to a bson.
 *
 * @param b the bson to append to.
 *
 * @return BSON_OK or BSON_ERROR.
 */
int bson_append_finish_object( bson *b );

/**
 * Finish appending a new object or array to a bson. This
 * is simply an alias for bson_append_finish_object.
 *
 * @param b the bson to append to.
 *
 * @return BSON_OK or BSON_ERROR.
 */
int bson_append_finish_array( bson *b );

void bson_numstr( char *str, int i );

void bson_incnumstr( char *str );

/* Error handling and standard library function over-riding. */
/* -------------------------------------------------------- */

/* bson_err_handlers shouldn't return!!! */
typedef void( *bson_err_handler )( const char *errmsg );

typedef int (*bson_printf_func)( const char *, ... );
typedef int (*bson_fprintf_func)( FILE *, const char *, ... );
typedef int (*bson_sprintf_func)( char *, const char *, ... );

extern void *( *bson_malloc_func )( size_t );
extern void *( *bson_realloc_func )( void *, size_t );
extern void ( *bson_free_func )( void * );

extern bson_printf_func bson_printf;
extern bson_fprintf_func bson_fprintf;
extern bson_sprintf_func bson_sprintf;
extern bson_printf_func bson_errprintf;

void bson_free( void *ptr );

/**
 * Allocates memory and checks return value, exiting fatally if malloc() fails.
 *
 * @param size bytes to allocate.
 *
 * @return a pointer to the allocated memory.
 *
 * @sa malloc(3)
 */
void *bson_malloc( int size );

/**
 * Changes the size of allocated memory and checks return value,
 * exiting fatally if realloc() fails.
 *
 * @param ptr pointer to the space to reallocate.
 * @param size bytes to allocate.
 *
 * @return a pointer to the allocated memory.
 *
 * @sa realloc()
 */
void *bson_realloc( void *ptr, int size );

/**
 * Set a function for error handling.
 *
 * @param func a bson_err_handler function.
 *
 * @return the old error handling function, or NULL.
 */
bson_err_handler set_bson_err_handler( bson_err_handler func );

/* does nothing if ok != 0 */
/**
 * Exit fatally.
 *
 * @param ok exits if ok is equal to 0.
 */
void bson_fatal( int ok );

/**
 * Exit fatally with an error message.
  *
 * @param ok exits if ok is equal to 0.
 * @param msg prints to stderr before exiting.
 */
void bson_fatal_msg( int ok, const char *msg );

/**
 * Invoke the error handler, but do not exit.
 *
 * @param b the buffer object.
 */
void bson_builder_error( bson *b );

/**
 * Cast an int64_t to double. This is necessary for embedding in
 * certain environments.
 *
 */
double bson_int64_to_double( int64_t i64 );

void bson_swap_endian32( void *outp, const void *inp );
void bson_swap_endian64( void *outp, const void *inp );

/* Excerpt from mongo.h */

typedef int SOCKET;

enum { /* converted from #defines for ffi */
  MONGO_ERR_LEN = 128,
  MAXHOSTNAMELEN = 256,
  MONGO_OK = 0,
  MONGO_ERROR = -1  
};

typedef enum mongo_error_t {
    MONGO_CONN_SUCCESS = 0,  /**< Connection success! */
    MONGO_CONN_NO_SOCKET,    /**< Could not create a socket. */
    MONGO_CONN_FAIL,         /**< An error occured while calling connect(). */
    MONGO_CONN_ADDR_FAIL,    /**< An error occured while calling getaddrinfo(). */
    MONGO_CONN_NOT_MASTER,   /**< Warning: connected to a non-master node (read-only). */
    MONGO_CONN_BAD_SET_NAME, /**< Given rs name doesn't match this replica set. */
    MONGO_CONN_NO_PRIMARY,   /**< Can't find primary in replica set. Connection closed. */

    MONGO_IO_ERROR,          /**< An error occurred while reading or writing on the socket. */
    MONGO_SOCKET_ERROR,      /**< Other socket error. */
    MONGO_READ_SIZE_ERROR,   /**< The response is not the expected length. */
    MONGO_COMMAND_FAILED,    /**< The command returned with 'ok' value of 0. */
    MONGO_WRITE_ERROR,       /**< Write with given write_concern returned an error. */
    MONGO_NS_INVALID,        /**< The name for the ns (database or collection) is invalid. */
    MONGO_BSON_INVALID,      /**< BSON not valid for the specified op. */
    MONGO_BSON_NOT_FINISHED, /**< BSON object has not been finished. */
    MONGO_BSON_TOO_LARGE,    /**< BSON object exceeds max BSON size. */
    MONGO_WRITE_CONCERN_INVALID /**< Supplied write concern object is invalid. */
} mongo_error_t;

typedef enum mongo_cursor_error_t {
    MONGO_CURSOR_EXHAUSTED,  /**< The cursor has no more results. */
    MONGO_CURSOR_INVALID,    /**< The cursor has timed out or is not recognized. */
    MONGO_CURSOR_PENDING,    /**< Tailable cursor still alive but no data. */
    MONGO_CURSOR_QUERY_FAIL, /**< The server returned an '$err' object, indicating query failure.
                                  See conn->lasterrcode and conn->lasterrstr for details. */
    MONGO_CURSOR_BSON_ERROR  /**< Something is wrong with the BSON provided. See conn->err
                                  for details. */
} mongo_cursor_error_t;

enum mongo_cursor_flags {
    MONGO_CURSOR_MUST_FREE = 1,      /**< mongo_cursor_destroy should free cursor. */
    MONGO_CURSOR_QUERY_SENT = ( 1<<1 ) /**< Initial query has been sent. */
};

enum mongo_index_opts {
    MONGO_INDEX_UNIQUE = ( 1<<0 ),
    MONGO_INDEX_DROP_DUPS = ( 1<<2 ),
    MONGO_INDEX_BACKGROUND = ( 1<<3 ),
    MONGO_INDEX_SPARSE = ( 1<<4 )
};

enum mongo_update_opts {
    MONGO_UPDATE_UPSERT = 0x1,
    MONGO_UPDATE_MULTI = 0x2,
    MONGO_UPDATE_BASIC = 0x4
};

enum mongo_insert_opts {
    MONGO_CONTINUE_ON_ERROR = 0x1
};

enum mongo_cursor_opts {
    MONGO_TAILABLE = ( 1<<1 ),        /**< Create a tailable cursor. */
    MONGO_SLAVE_OK = ( 1<<2 ),        /**< Allow queries on a non-primary node. */
    MONGO_NO_CURSOR_TIMEOUT = ( 1<<4 ), /**< Disable cursor timeouts. */
    MONGO_AWAIT_DATA = ( 1<<5 ),      /**< Momentarily block for more data. */
    MONGO_EXHAUST = ( 1<<6 ),         /**< Stream in multiple 'more' packages. */
    MONGO_PARTIAL = ( 1<<7 )          /**< Allow reads even if a shard is down. */
};

enum mongo_operations {
    MONGO_OP_MSG = 1000,
    MONGO_OP_UPDATE = 2001,
    MONGO_OP_INSERT = 2002,
    MONGO_OP_QUERY = 2004,
    MONGO_OP_GET_MORE = 2005,
    MONGO_OP_DELETE = 2006,
    MONGO_OP_KILL_CURSORS = 2007
};

#pragma pack(1)
typedef struct {
    int len;
    int id;
    int responseTo;
    int op;
} mongo_header;

typedef struct {
    mongo_header head;
    char data;
} mongo_message;

typedef struct {
    int flag; /* FIX THIS COMMENT non-zero on failure */
    int64_t cursorID;
    int start;
    int num;
} mongo_reply_fields;

typedef struct {
    mongo_header head;
    mongo_reply_fields fields;
    char objs;
} mongo_reply;
#pragma pack()

typedef struct mongo_host_port {
    char host[255];
    int port;
    struct mongo_host_port *next;
} mongo_host_port;

typedef struct mongo_write_concern {
    int w;            /**< Number of total replica write copies to complete including the primary. */
    int wtimeout;     /**< Number of milliseconds before replication timeout. */
    int j;            /**< If non-zero, block until the journal sync. */
    int fsync;        /**< Same a j with journaling enabled; otherwise, call fsync. */
    const char *mode; /**< Either "majority" or a getlasterrormode. Overrides w value. */

    bson *cmd; /**< The BSON object representing the getlasterror command. */
} mongo_write_concern;

typedef struct {
    mongo_host_port *seeds;        /**< List of seeds provided by the user. */
    mongo_host_port *hosts;        /**< List of host/ports given by the replica set */
    char *name;                    /**< Name of the replica set. */
    bson_bool_t primary_connected; /**< Primary node connection status. */
} mongo_replica_set;

typedef struct mongo {
    mongo_host_port *primary;  /**< Primary connection info. */
    mongo_replica_set *replica_set;    /**< replica_set object if connected to a replica set. */
    int sock;                  /**< Socket file descriptor. */
    int flags;                 /**< Flags on this connection object. */
    int conn_timeout_ms;       /**< Connection timeout in milliseconds. */
    int op_timeout_ms;         /**< Read and write timeout in milliseconds. */
    int max_bson_size;         /**< Largest BSON object allowed on this connection. */
    bson_bool_t connected;     /**< Connection status. */
    mongo_write_concern *write_concern; /**< The default write concern. */

    mongo_error_t err;          /**< Most recent driver error code. */
    int errcode;                /**< Most recent errno or WSAGetLastError(). */
    char errstr[MONGO_ERR_LEN]; /**< String version of error. */
    int lasterrcode;            /**< getlasterror code from the server. */
    char lasterrstr[MONGO_ERR_LEN]; /**< getlasterror string from the server. */
} mongo;

typedef struct {
    mongo_reply *reply;  /**< reply is owned by cursor */
    mongo *conn;       /**< connection is *not* owned by cursor */
    const char *ns;    /**< owned by cursor */
    int flags;         /**< Flags used internally by this drivers. */
    int seen;          /**< Number returned so far. */
    bson current;      /**< This cursor's current bson object. */
    mongo_cursor_error_t err; /**< Errors on this cursor. */
    const bson *query; /**< Bitfield containing cursor options. */
    const bson *fields;/**< Bitfield containing cursor options. */
    int options;       /**< Bitfield containing cursor options. */
    int limit;         /**< Bitfield containing cursor options. */
    int skip;          /**< Bitfield containing cursor options. */
} mongo_cursor;

/*********************************************************************
Connection API
**********************************************************************/

/** Initialize sockets for Windows.
 */
void mongo_init_sockets( void );

/**
 * Initialize a new mongo connection object. You must initialize each mongo
 * object using this function.
 *
 *  @note When finished, you must pass this object to
 *      mongo_destroy( ).
 *
 *  @param conn a mongo connection object allocated on the stack
 *      or heap.
 */
void mongo_init( mongo *conn );

/**
 * Connect to a single MongoDB server.
 *
 * @param conn a mongo object.
 * @param host a numerical network address or a network hostname.
 * @param port the port to connect to.
 *
 * @return MONGO_OK or MONGO_ERROR on failure. On failure, a constant of type
 *   mongo_error_t will be set on the conn->err field.
 */
int mongo_client( mongo *conn , const char *host, int port );

/**
 * DEPRECATED - use mongo_client.
 * Connect to a single MongoDB server.
 *
 * @param conn a mongo object.
 * @param host a numerical network address or a network hostname.
 * @param port the port to connect to.
 *
 * @return MONGO_OK or MONGO_ERROR on failure. On failure, a constant of type
 *   mongo_error_t will be set on the conn->err field.
 */
int mongo_connect( mongo *conn , const char *host, int port );

/**
 * Set up this connection object for connecting to a replica set.
 * To connect, pass the object to mongo_replica_set_connect().
 *
 * @param conn a mongo object.
 * @param name the name of the replica set to connect to.
 * */
void mongo_replica_set_init( mongo *conn, const char *name );

/**
 * DEPRECATED - use mongo_replica_set_init.
 * Set up this connection object for connecting to a replica set.
 * To connect, pass the object to mongo_replset_connect().
 *
 * @param conn a mongo object.
 * @param name the name of the replica set to connect to.
 * */
void mongo_replset_init( mongo *conn, const char *name );

/**
 * Add a seed node to the replica set connection object.
 *
 * You must specify at least one seed node before connecting to a replica set.
 *
 * @param conn a mongo object.
 * @param host a numerical network address or a network hostname.
 * @param port the port to connect to.
 */
void mongo_replica_set_add_seed( mongo *conn, const char *host, int port );

/**
 * DEPRECATED - use mongo_replica_set_add_seed.
 * Add a seed node to the replica set connection object.
 *
 * You must specify at least one seed node before connecting to a replica set.
 *
 * @param conn a mongo object.
 * @param host a numerical network address or a network hostname.
 * @param port the port to connect to.
 */
void mongo_replset_add_seed( mongo *conn, const char *host, int port );

/**
 * Utility function for converting a host-port string to a mongo_host_port.
 *
 * @param host_string a string containing either a host or a host and port separated
 *     by a colon.
 * @param host_port the mongo_host_port object to write the result to.
 */
void mongo_parse_host( const char *host_string, mongo_host_port *host_port );

/**
 * Utility function for validation database and collection names.
 *
 * @param conn a mongo object.
 *
 * @return MONGO_OK or MONGO_ERROR on failure. On failure, a constant of type
 *   mongo_conn_return_t will be set on the conn->err field.
 *
 */
int mongo_validate_ns( mongo *conn, const char *ns );

/**
 * Connect to a replica set.
 *
 * Before passing a connection object to this function, you must already have called
 * mongo_set_replica_set and mongo_replica_set_add_seed.
 *
 * @param conn a mongo object.
 *
 * @return MONGO_OK or MONGO_ERROR on failure. On failure, a constant of type
 *   mongo_conn_return_t will be set on the conn->err field.
 */
int mongo_replica_set_client( mongo *conn );

/**
 * DEPRECATED - use mongo_replica_set_client.
 * Connect to a replica set.
 *
 * Before passing a connection object to this function, you must already have called
 * mongo_set_replset and mongo_replset_add_seed.
 *
 * @param conn a mongo object.
 *
 * @return MONGO_OK or MONGO_ERROR on failure. On failure, a constant of type
 *   mongo_conn_return_t will be set on the conn->err field.
 */
int mongo_replset_connect( mongo *conn );

/** Set a timeout for operations on this connection. This
 *  is a platform-specific feature, and only work on *nix
 *  system. You must also compile for linux to support this.
 *
 *  @param conn a mongo object.
 *  @param millis timeout time in milliseconds.
 *
 *  @return MONGO_OK. On error, return MONGO_ERROR and
 *    set the conn->err field.
 */
int mongo_set_op_timeout( mongo *conn, int millis );

/**
 * Ensure that this connection is healthy by performing
 * a round-trip to the server.
 *
 * @param conn a mongo connection
 *
 * @return MONGO_OK if connected; otherwise, MONGO_ERROR.
 */
int mongo_check_connection( mongo *conn );

/**
 * Try reconnecting to the server using the existing connection settings.
 *
 * This function will disconnect the current socket. If you've authenticated,
 * you'll need to re-authenticate after calling this function.
 *
 * @param conn a mongo object.
 *
 * @return MONGO_OK or MONGO_ERROR and
 *   set the conn->err field.
 */
int mongo_reconnect( mongo *conn );

/**
 * Close the current connection to the server. After calling
 * this function, you may call mongo_reconnect with the same
 * connection object.
 *
 * @param conn a mongo object.
 */
void mongo_disconnect( mongo *conn );

/**
 * Close any existing connection to the server and free all allocated
 * memory associated with the conn object.
 *
 * You must always call this function when finished with the connection object.
 *
 * @param conn a mongo object.
 */
void mongo_destroy( mongo *conn );

/**
 * Specify the write concern object that this connection should use
 * by default for all writes (inserts, updates, and deletes). This value
 * can be overridden by passing a write_concern object to any write function.
 *
 * @param conn a mongo object.
 * @param write_concern pointer to a write concern object.
 *
 */
void mongo_set_write_concern( mongo *conn,
        mongo_write_concern *write_concern );


/*********************************************************************
CRUD API
**********************************************************************/

/**
 * Insert a BSON document into a MongoDB server. This function
 * will fail if the supplied BSON struct is not UTF-8 or if
 * the keys are invalid for insert (contain '.' or start with '$').
 *
 * The default write concern set on the conn object will be used.
 *
 * @param conn a mongo object.
 * @param ns the namespace.
 * @param data the bson data.
 * @param custom_write_concern a write concern object that will
 *     override any write concern set on the conn object.
 *
 * @return MONGO_OK or MONGO_ERROR. If the conn->err
 *     field is MONGO_BSON_INVALID, check the err field
 *     on the bson struct for the reason.
 */
int mongo_insert( mongo *conn, const char *ns, const bson *data,
                               mongo_write_concern *custom_write_concern );

/**
 * Insert a batch of BSON documents into a MongoDB server. This function
 * will fail if any of the documents to be inserted is invalid.
 *
 * The default write concern set on the conn object will be used.
 *
 * @param conn a mongo object.
 * @param ns the namespace.
 * @param data the bson data.
 * @param num the number of documents in data.
 * @param custom_write_concern a write concern object that will
 *     override any write concern set on the conn object.
 * @param flags flags on this batch insert. Currently, this value
 *     may be 0 or MONGO_CONTINUE_ON_ERROR, which will cause the
 *     batch insert to continue even if a given insert in the batch fails.
 *
 * @return MONGO_OK or MONGO_ERROR.
 *
 */
int mongo_insert_batch( mongo *conn, const char *ns,
                                     const bson **data, int num, mongo_write_concern *custom_write_concern,
                                     int flags );

/**
 * Update a document in a MongoDB server.
 *
 * The default write concern set on the conn object will be used.
 *
 * @param conn a mongo object.
 * @param ns the namespace.
 * @param cond the bson update query.
 * @param op the bson update data.
 * @param flags flags for the update.
 * @param custom_write_concern a write concern object that will
 *     override any write concern set on the conn object.
 *
 * @return MONGO_OK or MONGO_ERROR with error stored in conn object.
 *
 */
int mongo_update( mongo *conn, const char *ns, const bson *cond,
                               const bson *op, int flags, mongo_write_concern *custom_write_concern );

/**
 * Remove a document from a MongoDB server.
 *
 * The default write concern set on the conn object will be used.
 *
 * @param conn a mongo object.
 * @param ns the namespace.
 * @param cond the bson query.
 * @param custom_write_concern a write concern object that will
 *     override any write concern set on the conn object.
 *
 * @return MONGO_OK or MONGO_ERROR with error stored in conn object.
 */
int mongo_remove( mongo *conn, const char *ns, const bson *cond,
                               mongo_write_concern *custom_write_concern );


/*********************************************************************
Write Concern API
**********************************************************************/

/**
 * Initialize a mongo_write_concern object. Effectively zeroes out the struct.
 *
 */
void mongo_write_concern_init( mongo_write_concern *write_concern );

/**
 * Finish this write concern object by serializing the literal getlasterror
 * command that will be sent to the server.
 *
 * You must call mongo_write_concern_destroy() to free the serialized BSON.
 *
 */
int mongo_write_concern_finish( mongo_write_concern *write_concern );

/**
 * Free the write_concern object (specifically, the BSON that it owns).
 *
 */
void mongo_write_concern_destroy( mongo_write_concern *write_concern );

/*********************************************************************
Cursor API
**********************************************************************/

/**
 * Find documents in a MongoDB server.
 *
 * @param conn a mongo object.
 * @param ns the namespace.
 * @param query the bson query.
 * @param fields a bson document of fields to be returned.
 * @param limit the maximum number of documents to retrun.
 * @param skip the number of documents to skip.
 * @param options A bitfield containing cursor options.
 *
 * @return A cursor object allocated on the heap or NULL if
 *     an error has occurred. For finer-grained error checking,
 *     use the cursor builder API instead.
 */
mongo_cursor *mongo_find( mongo *conn, const char *ns, const bson *query,
                                       const bson *fields, int limit, int skip, int options );

/**
 * Initalize a new cursor object.
 *
 * @param cursor
 * @param ns the namespace, represented as the the database
 *     name and collection name separated by a dot. e.g., "test.users"
 */
void mongo_cursor_init( mongo_cursor *cursor, mongo *conn, const char *ns );

/**
 * Set the bson object specifying this cursor's query spec. If
 * your query is the empty bson object "{}", then you need not
 * set this value.
 *
 * @param cursor
 * @param query a bson object representing the query spec. This may
 *   be either a simple query spec or a complex spec storing values for
 *   $query, $orderby, $hint, and/or $explain. See
 *   http://www.mongodb.org/display/DOCS/Mongo+Wire+Protocol for details.
 */
void mongo_cursor_set_query( mongo_cursor *cursor, const bson *query );

/**
 * Set the fields to return for this cursor. If you want to return
 * all fields, you need not set this value.
 *
 * @param cursor
 * @param fields a bson object representing the fields to return.
 *   See http://www.mongodb.org/display/DOCS/Retrieving+a+Subset+of+Fields.
 */
void mongo_cursor_set_fields( mongo_cursor *cursor, const bson *fields );

/**
 * Set the number of documents to skip.
 *
 * @param cursor
 * @param skip
 */
void mongo_cursor_set_skip( mongo_cursor *cursor, int skip );

/**
 * Set the number of documents to return.
 *
 * @param cursor
 * @param limit
 */
void mongo_cursor_set_limit( mongo_cursor *cursor, int limit );

/**
 * Set any of the available query options (e.g., MONGO_TAILABLE).
 *
 * @param cursor
 * @param options a bitfield storing query options. See
 *   mongo_cursor_bitfield_t for available constants.
 */
void mongo_cursor_set_options( mongo_cursor *cursor, int options );

/**
 * Return the current BSON object data as a const char*. This is useful
 * for creating bson iterators with bson_iterator_init.
 *
 * @param cursor
 */
const char *mongo_cursor_data( mongo_cursor *cursor );

/**
 * Return the current BSON object data as a const char*. This is useful
 * for creating bson iterators with bson_iterator_init.
 *
 * @param cursor
 */
const bson *mongo_cursor_bson( mongo_cursor *cursor );

/**
 * Iterate the cursor, returning the next item. When successful,
 *   the returned object will be stored in cursor->current;
 *
 * @param cursor
 *
 * @return MONGO_OK. On error, returns MONGO_ERROR and sets
 *   cursor->err with a value of mongo_error_t.
 */
int mongo_cursor_next( mongo_cursor *cursor );

/**
 * Destroy a cursor object. When finished with a cursor, you
 * must pass it to this function.
 *
 * @param cursor the cursor to destroy.
 *
 * @return MONGO_OK or an error code. On error, check cursor->conn->err
 *     for errors.
 */
int mongo_cursor_destroy( mongo_cursor *cursor );

/**
 * Find a single document in a MongoDB server.
 *
 * @param conn a mongo object.
 * @param ns the namespace.
 * @param query the bson query.
 * @param fields a bson document of the fields to be returned.
 * @param out a bson document in which to put the query result.
 *
 */
/* out can be NULL if you don't care about results. useful for commands */
int mongo_find_one( mongo *conn, const char *ns, const bson *query,
                                 const bson *fields, bson *out );


/*********************************************************************
Command API and Helpers
**********************************************************************/

/**
 * Count the number of documents in a collection matching a query.
 *
 * @param conn a mongo object.
 * @param db the db name.
 * @param coll the collection name.
 * @param query the BSON query.
 *
 * @return the number of matching documents. If the command fails,
 *     MONGO_ERROR is returned.
 */
double mongo_count( mongo *conn, const char *db, const char *coll,
                                 const bson *query );

/**
 * Create a compound index.
 *
 * @param conn a mongo object.
 * @param ns the namespace.
 * @param data the bson index data.
 * @param options a bitfield for setting index options. Possibilities include
 *   MONGO_INDEX_UNIQUE, MONGO_INDEX_DROP_DUPS, MONGO_INDEX_BACKGROUND,
 *   and MONGO_INDEX_SPARSE.
 * @param out a bson document containing errors, if any.
 *
 * @return MONGO_OK if index is created successfully; otherwise, MONGO_ERROR.
 */
int mongo_create_index( mongo *conn, const char *ns,
                                     const bson *key, int options, bson *out );

/**
 * Create a capped collection.
 *
 * @param conn a mongo object.
 * @param ns the namespace (e.g., "dbname.collectioname")
 * @param size the size of the capped collection in bytes.
 * @param max the max number of documents this collection is
 *   allowed to contain. If zero, this argument will be ignored
 *   and the server will use the collection's size to age document out.
 *   If using this option, ensure that the total size can contain this
 *   number of documents.
 */
int mongo_create_capped_collection( mongo *conn, const char *db,
        const char *collection, int size, int max, bson *out );

/**
 * Create an index with a single key.
 *
 * @param conn a mongo object.
 * @param ns the namespace.
 * @param field the index key.
 * @param options index options.
 * @param out a BSON document containing errors, if any.
 *
 * @return true if the index was created.
 */
bson_bool_t mongo_create_simple_index( mongo *conn, const char *ns,
        const char *field, int options, bson *out );

/**
 * Run a command on a MongoDB server.
 *
 * @param conn a mongo object.
 * @param db the name of the database.
 * @param command the BSON command to run.
 * @param out the BSON result of the command.
 *
 * @return MONGO_OK if the command ran without error.
 */
int mongo_run_command( mongo *conn, const char *db,
                                    const bson *command, bson *out );

/**
 * Run a command that accepts a simple string key and integer value.
 *
 * @param conn a mongo object.
 * @param db the name of the database.
 * @param cmd the command to run.
 * @param arg the integer argument to the command.
 * @param out the BSON result of the command.
 *
 * @return MONGO_OK or an error code.
 *
 */
int mongo_simple_int_command( mongo *conn, const char *db,
        const char *cmd, int arg, bson *out );

/**
 * Run a command that accepts a simple string key and value.
 *
 * @param conn a mongo object.
 * @param db the name of the database.
 * @param cmd the command to run.
 * @param arg the string argument to the command.
 * @param out the BSON result of the command.
 *
 * @return true if the command ran without error.
 *
 */
int mongo_simple_str_command( mongo *conn, const char *db,
        const char *cmd, const char *arg, bson *out );

/**
 * Drop a database.
 *
 * @param conn a mongo object.
 * @param db the name of the database to drop.
 *
 * @return MONGO_OK or an error code.
 */
int mongo_cmd_drop_db( mongo *conn, const char *db );

/**
 * Drop a collection.
 *
 * @param conn a mongo object.
 * @param db the name of the database.
 * @param collection the name of the collection to drop.
 * @param out a BSON document containing the result of the command.
 *
 * @return true if the collection drop was successful.
 */
int mongo_cmd_drop_collection( mongo *conn, const char *db,
        const char *collection, bson *out );

/**
 * Add a database user.
 *
 * @param conn a mongo object.
 * @param db the database in which to add the user.
 * @param user the user name
 * @param pass the user password
 *
 * @return MONGO_OK or MONGO_ERROR.
  */
int mongo_cmd_add_user( mongo *conn, const char *db,
                                     const char *user, const char *pass );

/**
 * Authenticate a user.
 *
 * @param conn a mongo object.
 * @param db the database to authenticate against.
 * @param user the user name to authenticate.
 * @param pass the user's password.
 *
 * @return MONGO_OK on sucess and MONGO_ERROR on failure.
 */
int mongo_cmd_authenticate( mongo *conn, const char *db,
        const char *user, const char *pass );

/**
 * Check if the current server is a master.
 *
 * @param conn a mongo object.
 * @param out a BSON result of the command.
 *
 * @return true if the server is a master.
 */
/* return value is master status */
bson_bool_t mongo_cmd_ismaster( mongo *conn, bson *out );

/**
 * Get the error for the last command with the current connection.
 *
 * @param conn a mongo object.
 * @param db the name of the database.
 * @param out a BSON object containing the error details.
 *
 * @return MONGO_OK if no error and MONGO_ERROR on error. On error, check the values
 *     of conn->lasterrcode and conn->lasterrstr for the error status.
 */
int mongo_cmd_get_last_error( mongo *conn, const char *db, bson *out );

/**
 * Get the most recent error with the current connection.
 *
 * @param conn a mongo object.
 * @param db the name of the database.
 * @param out a BSON object containing the error details.
 *
 * @return MONGO_OK if no error and MONGO_ERROR on error. On error, check the values
 *     of conn->lasterrcode and conn->lasterrstr for the error status.
 */
int mongo_cmd_get_prev_error( mongo *conn, const char *db, bson *out );

/**
 * Reset the error state for the connection.
 *
 * @param conn a mongo object.
 * @param db the name of the database.
 */
void mongo_cmd_reset_error( mongo *conn, const char *db );


/*********************************************************************
Utility API
**********************************************************************/

mongo* mongo_create( void );
void mongo_dispose(mongo* conn);
int mongo_get_err(mongo* conn);
int mongo_is_connected(mongo* conn);
int mongo_get_op_timeout(mongo* conn);
const char* mongo_get_primary(mongo* conn);
int mongo_get_socket(mongo* conn) ;
int mongo_get_host_count(mongo* conn);
const char* mongo_get_host(mongo* conn, int i);
mongo_cursor* mongo_cursor_create( void );
void mongo_cursor_dispose(mongo_cursor* cursor);
int  mongo_get_server_err(mongo* conn);
const char*  mongo_get_server_err_string(mongo* conn);

/**
 * Set an error on a mongo connection object. Mostly for internal use.
 *
 * @param conn a mongo connection object.
 * @param err a driver error code of mongo_error_t.
 * @param errstr a string version of the error.
 * @param errorcode Currently errno or WSAGetLastError().
 */
void __mongo_set_error( mongo *conn, mongo_error_t err,
                                     const char *errstr, int errorcode );
/**
 * Clear all errors stored on a mongo connection object.
 *
 * @param conn a mongo connection object.
 */
void mongo_clear_errors( mongo *conn );
]]

return mongo;
