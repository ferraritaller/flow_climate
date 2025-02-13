import {
  ApolloClient,
  InMemoryCache,
  ApolloProvider,
  createHttpLink,
} from "@apollo/client"
import { ReactElement } from "react"

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  ?.getAttribute("content")

const httpLink = createHttpLink({
  uri: "/graphql",
  useGETForQueries: false,
  credentials: "same-origin",
  headers: {
    "Sec-Fetch-Mode": "cors",
    "Sec-Fetch-Dest": "empty",
    "X-CSRF-Token": csrfToken,
  },
})

const client = new ApolloClient({
  link: httpLink,
  cache: new InMemoryCache(),
})

type ApiProviderProps = {
  children: ReactElement
}

const ApiProvider = ({ children }: ApiProviderProps) => {
  return <ApolloProvider client={client}>{children}</ApolloProvider>
}

export default ApiProvider
