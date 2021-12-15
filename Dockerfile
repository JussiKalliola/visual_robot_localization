ARG ROS_DISTRO
FROM nvidia/cuda:11.2.0-cudnn8-devel-ubuntu20.04 as cuda
FROM ros:$ROS_DISTRO-ros-base

# Add cuda&cudnn libraries
COPY --from=cuda /usr/local/cuda /usr/local/cuda
COPY --from=cuda /usr/lib/x86_64-linux-gnu/*libcudnn* /usr/lib/x86_64-linux-gnu/
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/usr/local/cuda/targets/x86_64-linux/lib/"
ENV PATH="${PATH}:/usr/local/cuda/bin"

# https://discourse.ros.org/t/ros-gpg-key-expiration-incident/20669
# Also, the ROS ppa has to be removed while curl is being installed
RUN /bin/bash -c "mv /etc/apt/sources.list.d/ros2-latest.list /etc/ros2-latest.list; \
		  apt-get update && apt-get install -y curl; \
		  mv /etc/ros2-latest.list /etc/apt/sources.list.d/ros2-latest.list; \
                 curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -; curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg"
		 
# COLMAP and dependencies
COPY ./third_party/colmap /opt/third_party/colmap
WORKDIR /opt/third_party/colmap
RUN /bin/bash -c "chmod +x install_additional_dependencies.sh; \
		   bash install_additional_dependencies.sh"	   
RUN /bin/bash -c "	cd colmap; \
			mkdir build; \
			cd build; \
			cmake ..; \
			make -j; \
			sudo make install"
		  
WORKDIR /opt/visual_robot_localization/src/third_party/hloc
RUN /bin/bash -c "chmod +x install_additional_dependencies.sh; \
		   bash install_additional_dependencies.sh"	
RUN /bin/bash -c "python3 setup.py install"

COPY . /opt/visual_robot_localization/src
WORKDIR /opt/visual_robot_localization/src
RUN /bin/bash -c "chmod +x install_dependencies.sh; \
		  ./install_dependencies.sh"
		  
WORKDIR /opt/visual_robot_localization/
RUN /bin/bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash; \
		  colcon build" 
