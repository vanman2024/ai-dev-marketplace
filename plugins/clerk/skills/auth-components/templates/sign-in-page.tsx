import { SignIn } from '@clerk/nextjs'

export default function SignInPage() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-50 p-4">
      <SignIn
        appearance={{
          elements: {
            rootBox: "mx-auto",
            card: "shadow-lg border border-gray-200",
            headerTitle: "text-2xl font-bold text-gray-900",
            headerSubtitle: "text-gray-600",
            socialButtonsBlockButton: "border-2 border-gray-300 hover:border-gray-400 transition-colors",
            formButtonPrimary: "bg-blue-600 hover:bg-blue-700 transition-colors",
            formFieldInput: "border-gray-300 focus:border-blue-500 focus:ring-blue-500",
            footerActionLink: "text-blue-600 hover:text-blue-700"
          },
          layout: {
            shimmer: true,
            logoPlacement: 'inside'
          }
        }}
        afterSignInUrl="/dashboard"
        signUpUrl="/sign-up"
      />
    </div>
  )
}
