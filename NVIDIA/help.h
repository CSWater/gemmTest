#define GPU_TIMER_START(elapsed_time, event_start, event_stop) \
do { \
	elapsed_time = 0.0; \
	cuEventCreate(&event_start, CU_EVENT_BLOCKING_SYNC);	\
	cuEventCreate(&event_stop, CU_EVENT_BLOCKING_SYNC);		\
	cuEventRecord(event_start, NULL);	\
}while (0)

#define GPU_TIMER_END(elapsed_time, event_start, event_stop) \
do { \
	cuEventRecord(event_stop, NULL);	\
	cuEventSynchronize(event_stop);		\
	cuEventElapsedTime(&elapsed_time, event_start, event_stop);	\
	elapsed_time /= 1000.0;	\
}while (0)
	
