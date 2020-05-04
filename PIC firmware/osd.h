#ifndef OSD_H_INCLUDED
#define	OSD_H_INCLUDED

/*constants*/
#define	OSDCTRLUP		0x01u		/*OSD up control*/
#define	OSDCTRLDOWN		0x02u		/*OSD down control*/
#define	OSDCTRLSELECT	0x04u		/*OSD select control*/
#define	OSDCTRLMENU		0x08u		/*OSD menu control*/

/*functions*/
void OsdWrite(unsigned char n,const char *s, int inver);
void OsdClear(void);
void OsdEnable(void);
void OsdDisable(void);
void OsdReset(unsigned char boot);
void OsdFilter(unsigned char lr_filter, unsigned char hr_filter);
void OsdMemoryConfig(unsigned char memcfg);
unsigned char OsdGetCtrl(void);

#endif
