package main

import (
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ses"
	log "github.com/sirupsen/logrus"
	"os"
	"strconv"
	"strings"
)

func send_balance_email(recipient_email string, card_id int) {

	c, err := db_get_card_from_card_id(card_id)
	if err != nil {
		log.Warn(err.Error())
		return
	}

	card_total_sats, err := db_get_card_total_sats(card_id)
	if err != nil {
		log.Warn(err.Error())
		return
	}

	email_max_txs, err := strconv.Atoi(os.Getenv("EMAIL_MAX_TXS"))
	if err != nil {
		log.Warn(err.Error())
		return
	}

	txs, err := db_get_card_txs(card_id, email_max_txs+1)
	if err != nil {
		log.Warn(err.Error())
		return
	}

	subject := c.card_name + " balance = " + strconv.Itoa(card_total_sats) + " sats"

	// add transactions to the email body

	var html_body_sb strings.Builder
	var text_body_sb strings.Builder

	html_body_sb.WriteString("<!DOCTYPE html><html><head><style> table, " +
		"th, td { border: 1px solid black; border-collapse: collapse; } " +
		"</style></head><body>")

	html_body_sb.WriteString("<h3>transactions</h3><table><tr><th>date</th><th>action</th><th>amount</th>")
	text_body_sb.WriteString("transactions\n\n")

	for i, tx := range txs {

		if i < email_max_txs {
			html_body_sb.WriteString(
				"<tr>" +
					"<td>" + tx.tx_time + "</td>" +
					"<td>" + tx.tx_type + "</td>" +
					"<td style='text-align:right'>" + strconv.Itoa(tx.tx_amount_msats/1000) + "</td>" +
					"</tr>")
		} else {
			html_body_sb.WriteString(
				"<tr>" +
					"<td style='text-align:center'> ... </td>" +
					"<td style='text-align:center'> ... </td>" +
					"<td style='text-align:center'> ... </td>" +
					"</tr>")
		}

		text_body_sb.WriteString(tx.tx_type +
			" " + strconv.Itoa(tx.tx_amount_msats/1000))
	}

	html_body_sb.WriteString("</table></body></html>")

	html_body := html_body_sb.String()
	text_body := text_body_sb.String()

	send_email(recipient_email,
		subject,
		html_body,
		text_body)
}

// https://docs.aws.amazon.com/sdk-for-go/v1/developer-guide/ses-example-send-email.html

func send_email(recipient string, subject string, htmlBody string, textBody string) {

	aws_ses_id := os.Getenv("AWS_SES_ID")
	aws_ses_secret := os.Getenv("AWS_SES_SECRET")
	sender := os.Getenv("AWS_SES_EMAIL_FROM")

	sess, err := session.NewSession(&aws.Config{
		Region:      aws.String("us-east-1"),
		Credentials: credentials.NewStaticCredentials(aws_ses_id, aws_ses_secret, ""),
	})

	svc := ses.New(sess)

	charSet := "UTF-8"

	input := &ses.SendEmailInput{
		Destination: &ses.Destination{
			CcAddresses: []*string{},
			ToAddresses: []*string{
				aws.String(recipient),
			},
		},
		Message: &ses.Message{
			Body: &ses.Body{
				Html: &ses.Content{
					Charset: aws.String(charSet),
					Data:    aws.String(htmlBody),
				},
				Text: &ses.Content{
					Charset: aws.String(charSet),
					Data:    aws.String(textBody),
				},
			},
			Subject: &ses.Content{
				Charset: aws.String(charSet),
				Data:    aws.String(subject),
			},
		},
		Source: aws.String(sender),
		//ConfigurationSetName: aws.String(ConfigurationSet),
	}

	result, err := svc.SendEmail(input)

	if err != nil {
		if aerr, ok := err.(awserr.Error); ok {
			switch aerr.Code() {
			case ses.ErrCodeMessageRejected:
				log.Warn(ses.ErrCodeMessageRejected, aerr.Error())
			case ses.ErrCodeMailFromDomainNotVerifiedException:
				log.Warn(ses.ErrCodeMailFromDomainNotVerifiedException, aerr.Error())
			case ses.ErrCodeConfigurationSetDoesNotExistException:
				log.Warn(ses.ErrCodeConfigurationSetDoesNotExistException, aerr.Error())
			default:
				log.Warn(aerr.Error())
			}
		} else {
			log.Warn(err.Error())
		}

		return
	}

	log.WithFields(log.Fields{"result": result}).Info("email sent")
}
