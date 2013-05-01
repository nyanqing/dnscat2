/* session.h
 * By Ron Bowes
 * March, 2013
 *
 * Track the session - sequence numbers, state, data buffers, etc.
 *
 * Data is queued for sending via session_send(). Received data is simply
 * displayed, currently, but in future versions it will be returned to the
 * main program somehow. TODO: Update this
 * 
 * Note that this has to manage the session properly - via SYN/MSG/FIN - and
 * this also splits data into the proper-length chunks for the protocol. As
 * such, the send/receives aren't immediate, but are buffered.
 */

#ifndef __SESSION_H__
#define __SESSION_H__

#include <stdint.h>

#include "buffer.h"
#include "select_group.h"

typedef void(driver_send_t)(uint8_t *data, size_t length, void *param);

typedef enum
{
  SESSION_STATE_NEW,
  SESSION_STATE_ESTABLISHED
} session_state_t;

typedef struct
{
  /* Session information */
  uint16_t        id;
  session_state_t state;
  uint16_t        their_seq;
  uint16_t        my_seq;
  NBBOOL          is_closed;

  select_group_t *group;

  driver_send_t  *driver_send;
  void           *driver_send_param;

  int             max_packet_size;

  buffer_t       *incoming_data;
  buffer_t       *outgoing_data;
} session_t;

session_t *session_create(driver_send_t *driver_send, void *driver_send_param);
void       session_destroy(session_t *session);

void       session_recv(session_t *session, uint8_t *data, size_t length);
void       session_send(session_t *session, uint8_t *data, size_t length);
void       session_close(session_t *session);
void       session_force_close(session_t *session);

void       session_do_actions(session_t *session);

void       session_register_socket(session_t *session, int s, SOCKET_TYPE_t type, select_recv *recv_callback, select_closed *closed_callback, void *param);
void       session_unregister_socket(session_t *session, int s);

void       session_go(session_t *session);

#endif