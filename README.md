# Lightweight Edge Intelligence System for Road Incident Sound Recognition based on ShuffleNet

## Project Overview

This project aims to address the limitations of traditional road monitoring systems, which often fail to detect incidents outside the camera's field of view. Our solution leverages sound recognition to provide a comprehensive traffic accident monitoring system, enhancing real-time detection and response efficiency.

## Introduction

With the rapid increase in traffic volume, the frequency of road incidents has also risen. Traditional monitoring systems are limited by visual blind spots and rely heavily on video recognition, which cannot detect incidents outside the camera's field of view. This project proposes a lightweight edge intelligence system based on ShuffleNet for road incident sound recognition, utilizing the propagation characteristics of sound to complement visual monitoring and provide a complete traffic incident detection solution.

## Key Features

1. **Sound-Based Incident Detection**: The system detects road incidents by recognizing specific sounds associated with accidents, overcoming the limitations of visual-only monitoring systems.
2. **Edge Computing**: Real-time incident detection is performed at the edge, reducing the latency associated with sending data to a remote server for processing.
3. **High Efficiency and Lightweight Design**: The system is designed to be highly efficient and lightweight, suitable for deployment on resource-constrained FPGA hardware.

## Technical Approach

### Data Collection and Preprocessing

- **Sound Dataset**: The dataset includes real traffic accident sounds and synthetic sound effects, ensuring a comprehensive training set.
- **Preprocessing Techniques**: Mel-frequency spectral coefficients (MFSC) are used to convert audio signals into spectrograms suitable for neural network training.

### Neural Network Design

- **ShuffleNet Architecture**: The system uses a ShuffleNet neural network, which balances high accuracy with low computational complexity, making it ideal for edge deployment.
- **Model Training**: The network is trained on the preprocessed sound data to achieve high recognition accuracy while maintaining a lightweight model.

### Hardware Implementation

- **FPGA Deployment**: The trained ShuffleNet model is implemented on an FPGA, utilizing parallel processing and pipelining techniques to enhance performance.
- **Efficient Memory Usage**: The system employs a ping-pong RAM design and optimized memory control to handle real-time audio data processing.

## Results

- **High Recognition Accuracy**: The system achieves a recognition accuracy of 92.7% on the test set, with an F1 score of 93.9%.
- **Resource Efficiency**: The FPGA implementation is highly resource-efficient, making it suitable for deployment in real-world scenarios with limited hardware resources.

## Conclusion

This project demonstrates the potential of using sound recognition to overcome the visual limitations of traditional road monitoring systems. By integrating sound recognition with edge computing, the system provides a practical and effective solution for real-time traffic incident detection and response.

## Future Work

Future enhancements may include integrating video recognition to create a multi-modal detection system, further improving the accuracy and robustness of traffic incident monitoring.


[![Teamwork](https://img.shields.io/badge/teamwork-green.svg)](https://example.com)

