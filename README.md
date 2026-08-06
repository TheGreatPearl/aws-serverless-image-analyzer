![CI/CD Pipeline](https://github.com/TheGreatPearl/aws-serverless-image-analyzer/actions/workflows/main.yml/badge.svg)

# Serverless AI Image Analyzer & API

A fully serverless cloud architecture built on AWS that automatically analyzes uploaded images using computer vision (AWS Rekognition), stores detected labels in a NoSQL database (DynamoDB), dispatches instant notifications (SNS), and exposes a RESTful endpoint via API Gateway.

## Features

- **Automated Triggering:** Instant execution upon image upload to S3.
- **AI Label Detection:** Extracts objects, concepts, and scenes using Amazon Rekognition.
- **Data Persistence:** Stores image metadata and detected labels in Amazon DynamoDB.
- **Pub/Sub Alerts:** Sends real-time analysis alerts via Amazon SNS.
- **REST API:** Exposes `GET /images` via HTTP API Gateway to serve metadata in JSON format.
- **Infrastructure as Code (IaC):** Fully provisioned infrastructure using Terraform.
- **CI/CD Pipeline:** Automated code validation and syntax checks via GitHub Actions.

## Tech Stack & Services

- **IaC & Automation:** Terraform, GitHub Actions
- **Compute:** AWS Lambda (Python 3.11 / Boto3)
- **Storage & Database:** Amazon S3, Amazon DynamoDB
- **AI & Messaging:** Amazon Rekognition, Amazon SNS
- **API Gateway:** Amazon API Gateway (HTTP API)

## API Endpoints

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/images` | Retrieves all analyzed image records and detected labels. |

## Repository Structure
