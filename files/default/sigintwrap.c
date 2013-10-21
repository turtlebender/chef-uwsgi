/*

SIGINT wrapper for lighttpd graceful restart feature under runit.
by Zik 

("inspired by" execwrap by Sune Foldager) */



/* Errors */

#define RC_TARGET               13
#define RC_SIGNAL_HANDLER       15
#define RC_EXEC                 23
#define RC_BAD_OPTION           24


/* INC */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>
#include <signal.h>


/* Child PID */
int pid;


/* sighandler */
void sigHandler(int signal)
{
    /* Not forked yet */
    if (!pid)
	return;

    switch( signal )
    {
	case SIGHUP:
	case SIGUSR1:
	case SIGUSR2:
	    /* Forward to child */
	    kill( pid, signal );
	    break;
	    
	case SIGINT:
	    /* Forward signal and we exit */
	    kill( pid, SIGINT );
	    _exit( 0 );

	case SIGTERM:
	    /* Transform to graceful stop */
	    kill( pid, SIGINT );
	    break;
  
	case SIGQUIT:
	    /* Mapped to SIGTERM */
	    kill( pid, SIGTERM );
	    break;
	    
	/* No SIGKILL. We could map some other signal to sigkill, but it seems pointless. */
    }
}



void checkSignal( void *res )
{
    if ( res == SIG_ERR )
    {
	fprintf( stderr, "Error setting up signal handler" );
	exit( RC_SIGNAL_HANDLER );
    }
}


int main(int argc, char* argv[], char* envp[])
{

  /* Command line args */
  if(argc < 2)
  {
    fprintf( stderr, "Usage:\t%s target [options]\n", argv[0] );
    return( -1 );
  }

  char* target = argv[1];
  
  /* Install the signal handler */
  checkSignal( signal(SIGHUP,	sigHandler));
  checkSignal( signal(SIGINT,	sigHandler));
  checkSignal( signal(SIGQUIT,	sigHandler));
  checkSignal( signal(SIGTERM,	sigHandler));
  checkSignal( signal(SIGUSR1,	sigHandler));
  checkSignal( signal(SIGUSR2,	sigHandler));
  checkSignal( signal(SIGPIPE,	SIG_IGN));
  checkSignal( signal(SIGALRM,	SIG_IGN));

  /* Fork */
  if (!(pid = fork()))
  {
    /* execute */
    execve(target, & argv[1], envp);
    fprintf( stderr, "Error executing target: %s", target );
    return RC_EXEC;
  }

  /* Wait for the child to exit then return. (Or we exit from signal handler.) */
  int status;
  wait(&status);
  return status;

}

