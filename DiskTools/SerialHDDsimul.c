/** \file dastaZ80_HDDsimul.c
 *  \author David Asta
 *  \brief HDD simulator for dastaZ80 homebrew computer
 *  \details This programs runs on a Linux machine with an FTDI-to-USB cable 
 *           connected to the dastaZ80's SIO/2 Channel B port (only RX and TX
 *           are required). It receives bytes (commands) from the dastaZ80 and
 *           replies bytes like the ASMDC SDcard controller does.
 * \bug Saving fails for unknown reason.
 *  \copyright The MIT License
 *  \date 25 Nov 2023
 *  \version 1.0.0
 */ 

/* ---- INCLUDE ---- */
#include <stdio.h>
#include <stdbool.h>    // true, false, bool type
#include <string.h>     // strlen()
#include <stdlib.h>		// EXIT_SUCCESS, EXIT_FAILURE
#include <fcntl.h>		// file controls (e.g. O_RDWR)
#include <errno.h>		// strerror()
#include <termios.h>	// POSIX terminal control definitions
#include <unistd.h>		// write(), read(), close()
#include <sys/file.h>	// flock()
#include <sys/ioctl.h>	// ioctl()

/* ---- DEFINES ---- */
#define DEBUG               true    /**< Print extra information if DEBUG=true */
#define SERIAL_BUFFER       520     /**< Size of the receiving buffer */
#define SECTOR_SIZE         512     /**< Size of sector in DZFS */
#define SD_CMD_GET_STATUS   0xB0    /**< SD Command Get Status */
#define SD_CMD_BUSY         0xB1    /**< SD Command Busy */
#define SD_CMD_READ_SEC     0xB2    /**< SD Command Read Sector (512 bytes) */
#define SD_CMD_WRITE_SEC    0xB3    /**< SD Command Write Sector(512 bytes) */
#define SD_CMD_CLOSE_IMG    0xB4    /**< SD Command Close a Disk Image */
#define SD_CMD_OPEN_IMG     0xB5    /**< SD Command Open a Disk Image */
#define SD_CMD_IMG_INFO     0xB6    /**< SD Command Get information about a Disk Image */
#define MIN_CMD             0xB0    /**< Lowest command available */
#define MAX_CMD             0xB6    /**< Highest command available */

#define SD_ERR_NOSD         0x01    /**< Value returned when error for no SD detected */
#define SD_ERR_NOIMG        0x02    /**< Value returned when no Disk Images where opened */

#define SD_CMD_GET_STATUS_TXT   "SD Card Get Status"            /**< Text for DEBUG */
#define SD_CMD_BUSY_TXT         "SD Card Get Busy"              /**< Text for DEBUG */
#define SD_CMD_READ_SEC_TXT     "SD Card Read Sector"           /**< Text for DEBUG */
#define SD_CMD_WRITE_SEC_TXT    "SD Card Write Sector"          /**< Text for DEBUG */
#define SD_CMD_CLOSE_IMG_TXT    "SD Card Close Disk Image"      /**< Text for DEBUG */
#define SD_CMD_OPEN_IMG_TXT     "SD Card Open Disk Image"       /**< Text for DEBUG */
#define SD_CMD_IMG_INFO_TXT     "SD Card Get Disk Image Info"   /**< Text for DEBUG */

#define MAX_DSK_IMG     16  /**< Max. number of Disk Images to be opened */

/* ---- TYPE DEFINITIONS ---- */
typedef unsigned char   u8;     /**< 8-bits   1 byte    (0, 255)          %d */
typedef unsigned int    u16;    /**< 16-bits  2 bytes   (0, 65535)        %u */

/* ---- BLOBAL VARIABLES ---- */
int serial_port;                    /**< Pointer to serial port (e.g /dev/ttyUSB0) */
bool sdcard_ok;                     /**< Flag SD card is present */
bool sdimg_ok;                      /**< Flag Disk Image is present */
bool last_cmd_ok;                   /**< Flag last SD command was without errors */
bool sd_is_busy;                    /**< Flag SD is busy (reading/writing) */
int total_images;                   /**< Total number of Disk Images found */
FILE *disks_images[MAX_DSK_IMG];    /**< Disk Images' pointers from open(). (0 not used. It's the FDD) */
char *disks_names[MAX_DSK_IMG];     /**< list of Disk Images (0 not used. It's the FDD) */
int disks_capacities[MAX_DSK_IMG];  /**< Disk Images' capacities (0 not used. It's the FDD) */

/* ---- FUNCTIONS ---- */

/**
 * Set port speed in bauds. Default is 115200bps
 * \param speed The speed in bauds to set the port to
 * \return speed_t Value for termios
 */
speed_t set_serport_speed(int speed){
    speed_t portspeed;
    char charspeed[7];

    memset(charspeed, '\0', sizeof(charspeed));

    switch(speed){
    case 300:
        portspeed = B300;
        strncpy(charspeed, "300", 4);
        break;
    case 1200:
        portspeed = B1200;
        strncpy(charspeed, "1200", 5);
        break;
    case 2400:
        portspeed = B2400;
        strncpy(charspeed, "2400", 5);
        break;
    case 4800:
        portspeed = B4800;
        strncpy(charspeed, "4800", 5);
        break;
    case 9600:
        portspeed = B9600;
        strncpy(charspeed, "9600", 5);
        break;
    case 38400:
        portspeed = B38400;
        strncpy(charspeed, "38400", 6);
        break;
    case 57600:
        portspeed = B57600;
        strncpy(charspeed, "57600", 6);
        break;
    default:
        portspeed = B115200;
        strncpy(charspeed, "115200", 7);
        break;
    }

    printf("\tPort speed set to: %s bps\n", charspeed);

    return portspeed;
}

/**
 * Configures the serial port (speed, parity, etc.)
 * \param port The port (in text format) to be opened (e.g. /dev/ttyUSB0)
 * \param serportspeed The speedd for the port
 * \return 0 on Success
 * \return 1 on Failure
 */
int config_serport(const char *port, int serportspeed){
    struct termios tty;

    serial_port = open(port, O_RDWR);

    // Get exclusive access to serial port
    if(flock(serial_port, LOCK_EX | LOCK_NB) == -1){
        printf("Serial port %s is already in use by another process\n", port);
        return EXIT_FAILURE;
    }

    // Read existing serial port settings
    if(tcgetattr(serial_port, &tty) != 0){
        printf("tcgetattr error: %i - %s\n", errno, strerror(errno));
        return EXIT_FAILURE;
    }

    // Set serial port settings
    tty.c_cflag &= ~PARENB;             // Parity disabled
    tty.c_cflag &= ~CSTOPB;             // 1 stop bit
    tty.c_cflag &= ~CSIZE;              // Clear data size
    tty.c_cflag |= CS8;                 // 8 bits per byte
    tty.c_cflag &= ~CRTSCTS;            // Disable RTS/CTS (hardware flow control)
    tty.c_cflag |= CREAD | CLOCAL;      // Turn on READ, and ignore control lines

    tty.c_lflag &= ~ICANON;             // Disable Linux Canonical Mode (input only after ENTER )
    tty.c_lflag &= ~ECHO;               // Disable echo
    tty.c_lflag &= ~ECHOE;              // Disable erasure
    tty.c_lflag &= ~ECHONL;             // Disable newline echo
    tty.c_lflag &= ~ISIG;               // Disable interpretation of INTR, QUIT, SUSP

    tty.c_iflag &= ~(IXON | IXOFF |IXANY);    // Turn off software flow control
    tty.c_iflag &= ~(IGNBRK|BRKINT|PARMRK|ISTRIP|INLCR|IGNCR|ICRNL);    // Disable any special handling of received bytes

    tty.c_oflag &= ~OPOST;              // Prevent special interpretation of output bytes
    tty.c_oflag &= ~ONLCR;              // Prevent conversion of newline to CR/LF

    tty.c_cc[VTIME] = 10;    // wait 10 deciseconds or return as soon as any data is received
    tty.c_cc[VMIN] = 0;

    // Set baudrate
    cfsetospeed(&tty, set_serport_speed(serportspeed)); // Output baudrate
    cfsetispeed(&tty, 0);           // Input baudrate set to zero means equal to output baudrate

    // Save serial port seetings
    if(tcsetattr(serial_port, TCSANOW, &tty) != 0){
        printf("tcsetattr error: %i - %s\n", errno, strerror(errno));
        return EXIT_FAILURE;
    }

    printf("\tPort configured as: No echo. No parity. 8N1\n");
    printf("\t                    No hardware flow control (RTS/CTS)\n");
    printf("\t                    No software flow control\n");

    return EXIT_SUCCESS;
}

/**
 * Reads _disks.cfg and opens all the images listed in it
 * \param folder The location (folder) where _disks.cfg and all images are in Linux HDD
 * \return 0 on Success
 * \return 1 on Failure
 */
int open_disk_images(const char *folder){
    char *fullpath = malloc(sizeof(char) * (strlen(folder) + 1)); // path to folder + slash (/)
    char cfgline[80], imgfile[80];
    size_t len = 0;
    FILE *fcfg;
    int result;
    
    total_images = 0;

    // Build path to _disks.cfg
    strncat(fullpath, folder, strlen(folder));
    strncat(fullpath, "/", 2);
    chdir(fullpath);
    
    // Open _disks.cfg for read
    fcfg = fopen("_disks.cfg", "r");
    if(fcfg){
        sdimg_ok = true;
        // Read each line
        while(fgets(cfgline, 80, fcfg) != NULL){
            if(cfgline[0] != '#'){ // discard commented lines
                imgfile[0] = '\0';
                len = strlen(cfgline);
                cfgline[len - 1] = '\0';
                strncat(imgfile, cfgline, len - 2);
                disks_images[total_images + 1] = fopen(imgfile, "rb");
                if(disks_images[total_images + 1] != NULL){
                    disks_names[total_images + 1] = malloc(sizeof(char) * strlen(imgfile));
                    sprintf(disks_names[total_images + 1], "%s", imgfile);
                    printf("\tOpened: %s ", disks_names[total_images + 1]);
                    fseek(disks_images[total_images + 1], 0L, SEEK_END);
                    disks_capacities[total_images + 1] = ftell(disks_images[total_images + 1]) / 1024 / 1024;
                    printf("%d MB\n", disks_capacities[total_images + 1]);
                    rewind(disks_images[total_images + 1]);

                    total_images++;
                }else{
                    printf("\t%s %s\n", imgfile, strerror(errno));
                }
            }
        }

        result = EXIT_SUCCESS;
    }else{
        printf("Failed to open: %s - %i %s\n", fullpath, errno, strerror(errno));
        result = EXIT_FAILURE;
    }

    fclose(fcfg);
    free(fullpath);
    return result;
}

/**
 * Sends a byte (through the serial) that tells if the SD Card is busy or not
 *      0x00 = Not busy, 0x01 = Busy
 */
void sd_cmd_busy(void){
    u8 byte0[1] = {0x00};
    u8 byte1[1] = {0x01};

    if(sd_is_busy){
        write(serial_port, byte1, 1);
        if(DEBUG) printf("<< Sent 0x01: Busy\n");
    }else{
        write(serial_port, byte0, 1);
        if(DEBUG) printf("<< Sent 0x00: Not busy\n");
    }
}

/**
 * Sends a byte (through the serial) that tells the status of the SD Card reader
 *      Low Nibble (0x00 if all OK)
 *          bit 0 = set if SD card was not found
 *          bit 1 = set if image file was not found
 *          bit 2 = set if last command resulted in error
 *          bit 3 = not used
 *      High Nibble (number of disk image files found)
 */
void sd_cmd_status(void){
    u8 status[1];

    // Put in High Nibble the number of disk image files found
    status[0] = total_images << 4;

    if(sdcard_ok   == false) status[0] = status[0] | 0x01;
    if(sdimg_ok    == false) status[0] = status[0] | 0x02;
    if(last_cmd_ok == false) status[0] = status[0] | 0x04;
    
    write(serial_port, status, 1);

    if(DEBUG){
        printf("<< Sent 0x%02x\n", status[0]);
        printf("\t num images: %d\n", total_images);
        printf("\t  sdcard_ok: %d\n", sdcard_ok);
        printf("\t   sdimg_ok: %d\n", sdimg_ok);
        printf("\tlast_cmd_ok: %d\n", last_cmd_ok);
    }
}

/**
 * Read a sector (512 bytes) from disk image and send the bytes via the
 *  serial port
 * \param rcvd_buffer The received bytes. Contains image number, and sector number to read
 */
void sd_cmd_read_sector(u8 *rcvd_buffer){
    u8 sector[SECTOR_SIZE];
    u8 img_num      = rcvd_buffer[1];
    u8 sector_lsb   = rcvd_buffer[2];
    u8 sector_msb   = rcvd_buffer[3];
    unsigned int sector_num = 0;

    if(DEBUG) printf("> Received 0x%02x\n", rcvd_buffer[2]);
    if(DEBUG) printf("> Received 0x%02x\n", rcvd_buffer[3]);

    sector_num = ((0 << 24) + (0 << 16) + (sector_msb << 8) + sector_lsb);
    sector_num *= SECTOR_SIZE;

    // Read Sector
    if(DEBUG) printf("\tReading from Sector: %d (0x%02x)\n", sector_num, sector_num);
    sd_is_busy = true;
    fseek(disks_images[img_num], sector_num, SEEK_SET);
    fread(sector, 1, SECTOR_SIZE, disks_images[img_num]);
       
    if(DEBUG){
        for(int b=0; b<SECTOR_SIZE; b++){
            if(b > 0 && b % 16 == 0) printf("\n");
            printf("%02x ", sector[b]);
        }
        printf("\n");
    }

    // Send sector bytes via serial
    write(serial_port, sector, SECTOR_SIZE);

    sd_is_busy = false;   
}

/**
 * Write a sector (512 bytes) to the disk image
 * \return The position of the last byte used from the buffer rcvd_buffer.
 *  last byte used = 515 = 1 (AMDC command) + 2 (sector number) + 512 (data)
 */
int sd_cmd_write_sector(u8 *rcvd_buffer){
    u8 img_num      = rcvd_buffer[1];
    u8 sector_lsb   = rcvd_buffer[2];
    u8 sector_msb   = rcvd_buffer[3];
    unsigned int sector_num = 0;
    u8 buffer[SECTOR_SIZE];
//    size_t written_bytes;

    if(DEBUG) printf("> Received 0x%02x\n", rcvd_buffer[2]);
    if(DEBUG) printf("> Received 0x%02x\n", rcvd_buffer[3]);

    // Copy received bytes (except first 4) into a temporary array
    for(int b=0; b<SECTOR_SIZE; b++){
        // Discard first 4 bytes (command, img number, sector number (lsb & msb)
        buffer[b] = rcvd_buffer[b + 4];
        if(DEBUG){
            if(b > 0 && b % 16 == 0) printf("\n");
            printf("%02x ", buffer[b]);
        }
    }

    if(DEBUG) printf("\n");

    sector_num = ((0 << 24) + (0 << 16) + (sector_msb << 8) + sector_lsb);
    sector_num *= SECTOR_SIZE;

    if(DEBUG) printf("\tWriting to Sector: %d (0x%02x) of %s\n", 
                        sector_num, sector_num, disks_names[img_num]);

    // Write Sector
    sd_is_busy = true;
/*    fseek(disks_images[img_num], sector_num, SEEK_SET);
    written_bytes = fwrite(buffer, sizeof(u8), SECTOR_SIZE, disks_images[img_num]);
    if(written_bytes < SECTOR_SIZE){
        printf("ERROR while writing to Sector %d of %s\n",
                                sector_num, disks_names[img_num]);
        printf("Written %ld bytes\n", written_bytes);
    }else{
        fflush(disks_images[img_num]);
    }
*/
    sd_is_busy = false;

    return SECTOR_SIZE + 4;    
}

/**
 * Closes an image file
 * \param rcvd_buffer Second byte contains the image file number
 */
void sd_cmd_close_img(u8 *rcvd_buffer){
    u8 img_num = rcvd_buffer[1];

    fclose(disks_images[img_num]);
}

/**
 * Opens an image file
 * \param rcvd_buffer Second byte contains the image file number
 */
void sd_cmd_open_img(u8 *rcvd_buffer){
    FILE *fp;
    u8 img_num = rcvd_buffer[1];

    fp = fopen(disks_names[img_num], "rb+");
    if(fp == NULL) last_cmd_ok = false;
    else fseek(disks_images[img_num], 0, SEEK_SET);
}

/**
 * Sends the image name and capacity of a specified image number.
 *      Image name is 12 characters (padded with spaces).
 *      Image capacity is 1 byte representing MB
 * \param rcvd_buffer Second byte contains the image file number
 */
void sd_cmd_info_img(u8 *rcvd_buffer){
    u8 img_num = rcvd_buffer[1];
    u8 bytepadding[1] = {0x20};
    u8 diskcapacity = disks_capacities[img_num];

    if(DEBUG) printf("> Received 0x%02x\n", rcvd_buffer[1]);

    // Send characters
    write(serial_port, disks_names[img_num], strlen(disks_names[img_num]));
    if(DEBUG) printf("<< Sent %s\n", disks_names[img_num]);
    // Add padding
    for(int p=strlen(disks_names[img_num]); p<12; p++){
        write(serial_port, bytepadding, 1);
        if(DEBUG) printf("<< Sent padding\n");
    }
    // Send capacity
    write(serial_port, &diskcapacity, 1);
    if(DEBUG) printf("<< Sent %d\n", diskcapacity);
}

/**
 * Loop that listens for bytes arriving from the serial port and calls the corresponding function
 * * \return 1 on Failure (there was an error reading bytes from the serial port)
 */
int listen_serial(void){
    int rcvd_bytes, avail_bytes, rcvd_pos;
    u8 cmd_byte;
    u8 rcvd_buffer[SERIAL_BUFFER];
    char cmds_descrip[8][30] = {SD_CMD_GET_STATUS_TXT,
                                SD_CMD_BUSY_TXT,
                                SD_CMD_READ_SEC_TXT,
                                SD_CMD_WRITE_SEC_TXT,
                                SD_CMD_CLOSE_IMG_TXT,
                                SD_CMD_OPEN_IMG_TXT,
                                SD_CMD_IMG_INFO_TXT};

    while(1){
        memset(rcvd_buffer, 0, sizeof(rcvd_buffer));
        rcvd_pos = 0;
        avail_bytes = 0;
    	rcvd_bytes = 0;
        
        // Wait for bytes available in serial port
        while(avail_bytes <= 0){
		    ioctl(serial_port, FIONREAD, &avail_bytes);
        }
            
		// Receive available bytes
        rcvd_bytes = read(serial_port, rcvd_buffer, avail_bytes);
        if(DEBUG) printf("Received %d bytes\n", rcvd_bytes);
        
      	if(rcvd_bytes < 0){
    		printf("Error reading: %s", strerror(errno));
	    	return EXIT_FAILURE;
        }

        if(rcvd_bytes > 0){
            while(rcvd_pos < SERIAL_BUFFER){
                cmd_byte = rcvd_buffer[rcvd_pos];
                if(cmd_byte >= MIN_CMD && cmd_byte <= MAX_CMD)
                    printf("Received 0x%02x: %s\n", cmd_byte, cmds_descrip[cmd_byte - MIN_CMD]);
                    else printf("Received 0x%02x: UNKNOWN\n", cmd_byte);

                switch(cmd_byte){
                case SD_CMD_GET_STATUS:
                    sd_cmd_status();
                    rcvd_pos++;
                    break;
                case SD_CMD_BUSY:
                    sd_cmd_busy();
                    rcvd_pos++;
                    break;
                case SD_CMD_READ_SEC:
                    sd_cmd_read_sector(rcvd_buffer);
                    rcvd_pos = SERIAL_BUFFER;
                    break;
                case SD_CMD_WRITE_SEC:
                    rcvd_pos = sd_cmd_write_sector(rcvd_buffer);
                    break;
                case SD_CMD_CLOSE_IMG:
                    sd_cmd_close_img(rcvd_buffer);
                    rcvd_pos += 2;
                    break;
                case SD_CMD_OPEN_IMG:
                    sd_cmd_open_img(rcvd_buffer);
                    rcvd_pos += 2;
                    break;
                case SD_CMD_IMG_INFO:
                    sd_cmd_info_img(rcvd_buffer);
                    rcvd_pos += 2;
                    break;
                default:
                    rcvd_pos++;
                    break;
                }

                if(rcvd_buffer[rcvd_pos] == 0) break;
			}
	    }
    }
}

/**
 * \brief main() function
 * \param argc
 * \param argv[]
 * \return 0 on Sucess
 * \return 1 on Failure
 */
int main(int argc, char **argv){
	int portspeed, result;
    char *speed;

    // Initialise Virtual SDcard values
    sdcard_ok = true;   // There is no SD card in this emulator, so always true
    sdimg_ok = false;
    last_cmd_ok = true; // Wasn't really used in the ASMDC
    sd_is_busy = false;

	// Check for arguments
	if(argc < 4){
		printf("usage: %s serial_port portspeed dskimages_folder\n", argv[0]);
		printf("          serial_port (e.g. /dev/ttyUSB0)\n");
		printf("          portspeed (e.g. 115200)\n");
		printf("          dskimages_folder: folder where .cfg and .dsk are\n");
    
		return EXIT_FAILURE;
	}	

	// Open serial port received as argument
    // Exit this program if error occurred
    printf("Configuring %s\n", argv[1]);
    portspeed = strtol(argv[2], &speed, 10);
    if(config_serport(argv[1], portspeed) == EXIT_FAILURE)
        return EXIT_FAILURE;

    printf("Configuring Disk Images at %s\n", argv[3]);
    if(open_disk_images(argv[3]) == EXIT_FAILURE){
        return EXIT_FAILURE;
    }
	
	printf("Waiting for receiving bytes\n");
   
    result = listen_serial();
 
	// Close serial port and exit
    // This is only reached if listen_serial() ended with and error while
    //  reading bytes from the serial port, because listen_serial() is an
    //  infinite loop.
	close(serial_port);
	return result;
}
