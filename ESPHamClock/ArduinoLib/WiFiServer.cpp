/* implement WiFiServer with UNIX sockets
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <signal.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <time.h>
#include <fcntl.h>
#include <ctype.h>
#include <pthread.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/resource.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <netdb.h>
#include <arpa/inet.h>

#include "WiFiClient.h"
#include "WiFiServer.h"

// set for more info
static bool _trace_server = true;

WiFiServer::WiFiServer(int newport)
{
	port = newport;
	socket = -1;
        if (_trace_server) printf ("WiFiSvr: new instance on port %d\n", port);
}

/* N.B. Arduino version returns void and no ynot
 */
bool WiFiServer::begin(char ynot[])
{
        struct sockaddr_in serv_socket;
        int sfd;
        int reuse = 1;

        if (_trace_server) printf ("WiFiSvr: starting server on port %d\n", port);

        /* make socket endpoint */
        if ((sfd = ::socket (AF_INET, SOCK_STREAM, 0)) < 0) {
            printf ("socket: %s\n", strerror(errno));
	    return (false);
	}

        /* bind to given port for any IP address */
        memset (&serv_socket, 0, sizeof(serv_socket));
        serv_socket.sin_family = AF_INET;
        serv_socket.sin_addr.s_addr = htonl (INADDR_ANY);
        serv_socket.sin_port = htons ((unsigned short)port);
        if (::setsockopt(sfd,SOL_SOCKET,SO_REUSEADDR,&reuse,sizeof(reuse)) < 0) {
            sprintf (ynot, "setsockopt: %s", strerror(errno));
	    close (sfd);
	    return (false);
	}
        if (::bind(sfd,(struct sockaddr*)&serv_socket,sizeof(serv_socket)) < 0) {
            sprintf (ynot, "bind: %s", strerror(errno));
	    close (sfd);
	    return (false);
	}

	/* set non-blocking */
        int flags = ::fcntl(sfd, F_GETFL, 0);
        if (flags < 0) {
	    sprintf (ynot, "fcntl(GETL): %s", strerror(errno));
	    close (sfd);
	    return (false);
	}
        flags |= O_NONBLOCK;
        if (::fcntl(sfd, F_SETFL, flags) < 0) {
	    sprintf (ynot, "fcntl(SETL): %s", strerror(errno));
	    close (sfd);
	    return (false);
	}

        /* willing to accept connections with a backlog of 5 pending */
        if (::listen (sfd, 50) < 0) {
            sprintf (ynot, "listen: %s", strerror(errno));
	    close (sfd);
	    return (false);
	}

        /* handle write errors inline */
        signal (SIGPIPE, SIG_IGN);

        /* ok */
        if (_trace_server) printf ("WiFiSvr: new server socket %d\n", sfd);
        socket = sfd;
        return (true);
}

WiFiClient WiFiServer::available()
{
        int cli_fd = -1;

        // get a private connection to new client unless server failed to build
        if (socket >= 0) {
            struct sockaddr_in cli_socket;
            socklen_t cli_len = sizeof(cli_socket);
            cli_fd = ::accept (socket, (struct sockaddr *)&cli_socket, &cli_len);
            if (cli_fd >= 0 && _trace_server) printf ("WiFiSvr: new server client fd %d\n", cli_fd);
        }

	// return as a client
	WiFiClient result(cli_fd);
        return (result);
}

void WiFiServer::stop()
{
        if (socket >= 0) {
            if (_trace_server) printf ("WiFiSvr: closing socket %d\n", socket);
            close (socket);
            socket = -1;
        }
}
